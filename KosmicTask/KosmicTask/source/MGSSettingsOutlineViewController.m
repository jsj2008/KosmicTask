//
//  MGSSettingsOutlineViewController.m
//  KosmicTask
//
//  Created by Jonathan on 02/10/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSSettingsOutlineViewController.h"
#import "MGSLanguageProperty.h"
#import "NSOutlineView_Mugginsoft.h"
#import "MGSLanguagePropertyManager.h"
#import "MLog.h"
#import "MGSLanguageSettingsTransformer.h"

const char MGSSettingsTreeSelectedObjectsContext;

// class extension
@interface MGSSettingsOutlineViewController()
- (void)languagePropertyOptionValueAction:(id)sender;
- (IBAction)resetAction:(id)sender;
- (void)buildSettingsTree;
- (NSTreeNode *)selectedSettingsTreeNode;
- (void)languagePropertyDidChangeValue:(NSNotification *)note;
@end

@implementation MGSSettingsOutlineViewController

@synthesize delegate, documentEdited, editable, settingsTree, languagePropertyManager,
selectedLanguageProperty, editedLanguageProperty;

#pragma mark -
#pragma mark Instance 
/*
 
 init
 
 */
- (id)init
{
	if ((self = [super initWithNibName:@"SettingsOutlineView" bundle:nil])) {
		documentEdited = NO;
		editable = YES;
	}
	return self;
}

#pragma mark -
#pragma mark Accessors

/*
 
 - setLanguageProperties:
 
 */
- (void)setLanguagePropertyManager:(MGSLanguagePropertyManager *)manager
{
	if (languagePropertyManager) {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:MGSNoteLanguagePropertyDidChangeValue object:languagePropertyManager];
	}

	languagePropertyManager = manager;

	// observer changes to properties
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(languagePropertyDidChangeValue:) 
												 name:MGSNoteLanguagePropertyDidChangeValue
											   object:manager];
	
	[self buildSettingsTree];
}

/*
 
 - setEditable:
 
 */
- (void)setEditable:(BOOL)value
{
    editable = value;
}
#pragma mark -
#pragma mark Nib
/*
 
 - awakeFromNib
 
 */
- (void)awakeFromNib
{

	/*
	 
	 bindings
	 
	 these were initially created in IB but then a refactor caused them to break
	 
	 note some text fields still bound in IB
	 
	 */
	NSDictionary *options = nil;
	
	// controllers
	[settingsTreeController bind:NSContentBinding toObject:self withKeyPath:@"settingsTree" options:nil];
	
	// KVO
	[settingsTreeController addObserver:self forKeyPath:@"selectedObjects" options:0 context:(void *)&MGSSettingsTreeSelectedObjectsContext];
	
	// settings outline view
	[settingsOutlineView bind:NSContentBinding toObject:settingsTreeController withKeyPath:@"arrangedObjects" options:nil];
	[settingsOutlineView bind:NSSelectionIndexPathsBinding toObject:settingsTreeController withKeyPath:@"selectionIndexPaths" options:nil];
	[[settingsOutlineView tableColumnWithIdentifier:@"setting"] bind:NSValueBinding toObject:settingsTreeController withKeyPath:@"arrangedObjects.representedObject.name" options:nil];	
	[[settingsOutlineView tableColumnWithIdentifier:@"value"] 
						bind:NSValueBinding toObject:settingsTreeController 
					withKeyPath:@"arrangedObjects.representedObject.value" 
					options:[NSDictionary dictionaryWithObjectsAndKeys:[MGSLanguageSettingsTransformer new], NSValueTransformerBindingOption, nil]];	
	
	// settings outline view editable binding
    [[settingsOutlineView tableColumnWithIdentifier:@"value"] bind:NSEditableBinding toObject:settingsTreeController withKeyPath:@"arrangedObjects.representedObject.editable" options:nil];	
	[[settingsOutlineView tableColumnWithIdentifier:@"value"] bind:[NSEditableBinding stringByAppendingString:@"2"] toObject:self withKeyPath:@"editable" options:nil];
	options = [NSDictionary dictionaryWithObjectsAndKeys: NSNegateBooleanTransformerName, NSValueTransformerNameBindingOption, nil];
	[[settingsOutlineView tableColumnWithIdentifier:@"value"] bind:[NSEditableBinding stringByAppendingString:@"3"] toObject:settingsTreeController withKeyPath:@"arrangedObjects.representedObject.isList" options:options];
	
	[settingsOutlineView setGridStyleMask:NSTableViewSolidVerticalGridLineMask | NSTableViewSolidHorizontalGridLineMask];
	[settingsOutlineView bind:NSSortDescriptorsBinding toObject:settingsTreeController withKeyPath:@"sortDescriptors" options:nil];
	
	// settings text view
	options = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:NO], NSConditionallySetsEditableBindingOption,
			   [NSNumber numberWithBool:YES], NSContinuouslyUpdatesValueBindingOption, 
			   [NSNumber numberWithBool:YES], NSValidatesImmediatelyBindingOption, nil];
	[settingsTextView setRichText:NO];	// must be NO NSValueBinding to be respected
	[settingsTextView bind:NSValueBinding toObject:self withKeyPath:@"selectedLanguageProperty.infoText" options:options];
}

#pragma mark -
#pragma mark NSOutlineView Delegate

/*
 
 - outlineView:shouldSelectItem:
 
 */
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
	
	if (outlineView == settingsOutlineView) {
		
		// we don't want to select the expandable items
		if ([outlineView isExpandable:item]) {
			return NO;
		}
	}
	
	return YES;
}


/*
 
 - outlineView:dataCellForTableColumn:item:
 
 it is important to just return the cell here and not make too many assumptions
 about how and when it will be used.
 
 leave setting the cell properties to  - outlineView:willDisplayCell:forTableColumn:item:
 
 */
- (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	// default cell
	id cell = [tableColumn dataCellForRow:[outlineView rowForItem:item]];
	
	if (outlineView == settingsOutlineView) {
		
		NSTableColumn *column1 = [outlineView tableColumnWithIdentifier:@"setting"];
		NSCell *cell1 = [column1 dataCellForRow:[outlineView rowForItem:item]];
		
		// if tableColumn is nil we are returning a cell to represent the whole row
		if (!tableColumn) {
			
			// use first column cell for expandable rows
			if ([outlineView isExpandable:item]) {
				
				// use the first column cell to draw the whole column.
				// this will prevent the gridline from appearing.
				return cell1;
			}
			
			return nil;
		}
		
		// use bold font in overridden cells
		MGSLanguageProperty *langProp = [[item representedObject] representedObject];
		if (![langProp isKindOfClass:[MGSLanguageProperty class]]) {
			return cell;
		}
				
		if ([[tableColumn identifier] isEqualToString:@"action"]) {
			
			
			// default cell has a reset button.
			// we only want to use the reset cell if the property can be reset
			if (!langProp.canReset || !langProp.editable || !langProp.allowReset) {
				return cell1;
			}
			
		} else if ([[tableColumn identifier] isEqualToString:@"value"]) {
			
            // a popup button cell wil be required if we have a number of options available
            // and the view is editable.
			if (langProp.optionValues && [langProp.optionValues count] > 0 && self.editable) {			
				return  smallPopUpButtonCell;
			}
		}
	}
	
	// return the default cell for the column
	return cell;
}

/*
 
 - outlineView:willDisplayCell:forTableColumn:item:

 set the cell properties prior to display
 
 Quincey pretty much got it right. Here's what happens:
 
 Table needs a cell (to draw, edit, type select, etc).
 
 It calls -preparedCellAtColumn:row: -- this is a public funnel point, and can be overridden. Some examples on the dev site do this.
 
 preparedCellAtColumn:row does this, in this order (which may change slightly from release to release):
 * Return the tracking or editing cell (which was copied), if it is that given row/column. No modifications to the cell are done.
 * Acquires a cell, via: 1. Asking the delegate, 2. if nil, call [tableColumn dataCellForRow:] (this returns what was set in the nib)
 * Sets the object value, as returned from the datasource (if applicable)
 * Calls into bindings to fill up the cell with bound data; this potentially overwrites the objectValue
 * Sets properties on the cell, such as highlighted, backgroundStyle, showsFirstResponder
 * Lastly, calls -willDisplayCell, where you get a chance to overwrite any values set by the tableview.
 
 corbin
 
 */
- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
#pragma unused(tableColumn)
	
	if (outlineView == settingsOutlineView) {
		
		MGSLanguageProperty *langProp = [[item representedObject] representedObject];
		if (![langProp isKindOfClass:[MGSLanguageProperty class]]) {
			return;
		}

		// action column
		if ([[tableColumn identifier] isEqualToString:@"action"]) {
			if ([cell isKindOfClass:[NSButtonCell class]]) {
				
				// set the target and the action.
				// note that when the action is called the sender will be the 
				// outline view not the cell
				[cell setTarget:self];
				[cell setAction:@selector(resetAction:)];
				
			}
			return;
		}
		
		// get font for modified properties
		NSFontTraitMask fontTrait = NSUnboldFontMask;
		if (langProp.canReset && langProp.editable && langProp.allowReset) {
			fontTrait = NSBoldFontMask;
		}
		NSFont *font = [cell font];
		font = [[NSFontManager sharedFontManager] convertFont:font toHaveTrait:fontTrait];
		
		// setting column
		if ([[tableColumn identifier] isEqualToString:@"setting"]) {
			[cell setFont:font];
		}
		
		// action column
		else if ([[tableColumn identifier] isEqualToString:@"value"]) {
			[cell setFont:font];

			// configure our popup button cell
			if ([cell isKindOfClass:[NSPopUpButtonCell class]]) {
				NSPopUpButtonCell *popupCell = cell;
				
				[popupCell removeAllItems];
				[popupCell setAltersStateOfSelectedItem:YES];
				
				NSMenuItem *menuItem = nil;
				for (NSNumber *key in [langProp sortedOptionKeys]) {
					
					NSString *menuTitle = [langProp.optionValues objectForKey:key];
					
					[popupCell addItemWithTitle:menuTitle];
					menuItem = [popupCell itemWithTitle:menuTitle];
					[menuItem setTarget:self];
					[menuItem setAction:@selector(languagePropertyOptionValueAction:)];
					[menuItem setRepresentedObject:langProp];
				}
				[popupCell selectItemWithTitle:langProp.value];
				
			} 
		}
	}
}

/*
 
 languagePropertyOptionValueAction
 
 */
- (void)languagePropertyOptionValueAction:(id)sender
{
	if (![sender isKindOfClass:[NSMenuItem class]]) return;
	
	MGSLanguageProperty *langProp = [(NSMenuItem *)sender representedObject];
	langProp.value = [(NSMenuItem *)sender title];
}

/*
 
 - outlineView:isGroupItem:
 
 */
- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{	
	if (outlineView == settingsOutlineView) {
		if ([outlineView isExpandable:item]) {
			return YES;
		}
	}
	
	return NO;
}

/*
 
 - mgs_outlineView:drawStyleForRow:
 
 */
-(NSInteger)mgs_outlineView:(NSOutlineView *)outlineView drawStyleForRow:(int)row
{
	NSInteger drawStyle = 0;
	
	if (outlineView == settingsOutlineView) {
		
		if ([outlineView isRowSelected:row]) return drawStyle;
		
		// drawstyle 1 for expandablerows
		if ([outlineView isExpandable:[outlineView itemAtRow:row]]) {
			drawStyle = 1;
		} else {
			
			NSTreeNode *node = [[outlineView itemAtRow:row] representedObject];
			
			MGSLanguageProperty *langProp = node.representedObject;
			if (!langProp) return 0;
			
			NSAssert([langProp isKindOfClass:[MGSLanguageProperty class]], @"bad node class");
			
			if (langProp.propertyType == kMGSLanguageProperty) {
				drawStyle = 2;
			} else {
				drawStyle = 3;
			}
		}
	}
	
	return drawStyle;
}

#pragma mark -
#pragma mark Actions

/*
 
 - resetAction:
 
 */
- (IBAction)resetAction:(id)sender
{
	// reset cell
	if (sender == settingsOutlineView) {
		
		NSInteger row = [settingsOutlineView clickedRow];
		if (row == -1) return;
		NSTreeNode *node = [[settingsOutlineView itemAtRow:row] representedObject];
		
		// reset language property
		if ([[node representedObject] isKindOfClass:[MGSLanguageProperty class]]) {
			MGSLanguageProperty *langProp = (MGSLanguageProperty *)[node representedObject];
			[langProp resetToInitialValue:self];
			
			self.documentEdited = YES;
		}
	}
}

#pragma mark -
#pragma mark Tree handling

/*
 
 - buildSettingsTree
 
 */
- (void)buildSettingsTree
{	
	NSAssert(self.languagePropertyManager, @"language property manager is nil");
	
	// get tree of settings
	NSMutableArray *tree = [self.languagePropertyManager treeForPropertyType:kMGSLanguagePropertyTypeAll];
	
	// assign the tree
	self.settingsTree = tree;
	
	[settingsOutlineView mgs_expandAll];
}

/*
 
 - selectedSettingsTreeNode
 
 */
- (NSTreeNode *)selectedSettingsTreeNode
{
	// selected tree objects
	NSArray *selectedObjects = [settingsTreeController selectedObjects];
	if ([selectedObjects count] == 0) {
		return nil;
	}
	
	// validate
	NSAssert([selectedObjects count] == 1, @"multiple selections not supported");
	NSTreeNode *selectedNode = [selectedObjects objectAtIndex:0];		
	NSAssert([selectedNode isKindOfClass:[NSTreeNode class]], @"invalid tree node class");
	
	return selectedNode;
}

#pragma mark -
#pragma mark KVO

/*
 
 - observeValueForKeyPath:ofObject:change:context:
 
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
#pragma unused(keyPath)
#pragma unused(object)
#pragma unused(change)
	
	[self commitEditing];
	
		// settings tree objects selection
	if (context == &MGSSettingsTreeSelectedObjectsContext) {
		
		NSTreeNode *selectedNode = [self selectedSettingsTreeNode];

		if ([selectedNode.representedObject isKindOfClass:[MGSLanguageProperty class]]) {
			self.selectedLanguageProperty = selectedNode.representedObject;
		}
	}
	
}

#pragma mark -
#pragma mark NSTextView delegate
/*
 
 - textDidChange:
 
 */
- (void)textDidChange:(NSNotification *)notification
{
#pragma unused(notification)
	
	self.documentEdited = YES;
}

/*
 
 - controlTextDidChange:
 
 */
- (void)controlTextDidChange:(NSNotification *)notification
{
#pragma unused(notification)
	
	self.documentEdited = YES;
}

#pragma mark MGSLanguagePropertyManager notifications

/*
 
 - languagePropertyDidChangeValue:
  
 */
- (void)languagePropertyDidChangeValue:(NSNotification *)note
{
#pragma unused(note)
	
	self.documentEdited = YES;
	
	self.editedLanguageProperty = [[note userInfo] objectForKey:MGSNoteKeyLanguageProperty];
}

@end
