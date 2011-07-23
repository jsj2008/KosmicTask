//
//  MGSListParameterEditViewController.m
//  Mother
//
//  Created by Jonathan on 08/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSListParameterEditViewController.h"
#import "MGSListParameterPlugin.h"
#import "MGSArrayController.h"

#define MyPrivateTableViewDataType @"MGSPrivateTableViewDataType"

#define MGSAddItem 0
#define MGSRemoveItem 1

/*
 
 list parameter item 
 
 */
@interface MGSListParameterItem:NSObject {
	NSString *_value;
	BOOL _isInitialValue;
	id _delegate;
}
@property (copy) NSString *value;
@property BOOL isInitialValue;
@property id delegate;


- (void)updateIsInitialValue:(BOOL)value;
- (NSDictionary *)dictionary;
- (id)initWithDictionary:(NSDictionary *)dict;

@end


@implementation MGSListParameterItem
@synthesize value = _value;
@synthesize isInitialValue = _isInitialValue;
@synthesize delegate = _delegate;


/*
 
 init
 
 */
- (id)init
{
	self = [super init];
	if (self) {
		self.value = @"";
		self.isInitialValue = NO;
	}
	return self;
}


/*
 
 init with dictionary
 
 */
- (id)initWithDictionary:(NSDictionary *)dict
{
	if ([super init]) {
		self.value = [dict objectForKey:@"Value"];
		self.isInitialValue = [[dict objectForKey:@"IsInitialValue"] boolValue];
	}
	return self;
}
/*
 
 set is initial value
 
 */
- (void)setIsInitialValue:(BOOL)value
{
	_isInitialValue = value;
	if (value) {
		[_delegate setIsInitialValue:value forItem:self];
	}
}
- (void)updateIsInitialValue:(BOOL)value
{
	_isInitialValue = value;
}
/* 
 
 dictionary
 
 */
- (NSDictionary *)dictionary
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
	[dict setObject:self.value forKey:@"Value"];
	
	if (self.isInitialValue == YES) {
		[dict setObject:[NSNumber numberWithBool:YES] forKey:@"IsInitialValue"];
	}
	
	return [NSDictionary dictionaryWithDictionary:dict];
}

// this will be called by the binding machinery to
// modify the model data
- (void)setValue:(id)value forKeyPath:(NSString *)keyPath
{
	[super setValue:value forKeyPath:keyPath];
	//NSLog(@"value = %@ keypath = %@", value, keyPath);
	[_delegate setModelDataModified:YES];
}
@end

@implementation MGSListParameterEditViewController

/*
 
 init  
 
 */
- (id)init
{
	if ([super initWithNibName:@"ListParameterEditView"]) {
				
		// controller
		_arrayController = [[NSArrayController alloc] init];
		[_arrayController setObjectClass:[MGSListParameterItem class]];
		self.parameterDescription = NSLocalizedString(@"Select an item from the list.", @"List selection prompt");

	}
	return self;
}



/*
 
 can drag middle view
 
 */
- (BOOL)canDragMiddleView
{
	return YES;
}

/*
 
 awake from nib
 
 */
// NSTableView drag and drop ordering
// http://borkware.com/quickies/one?topic=NSTableView
- (void)awakeFromNib
{
	// call our super implementation
	[super awakeFromNib];
	
	// observe arraycontroller
	[_arrayController addObserver:self forKeyPath:@"selectedObjects" options:NSKeyValueObservingOptionNew context:MGSSelectedObjectsContext];
	[_arrayController addObserver:self forKeyPath:@"arrangedObjects" options:NSKeyValueObservingOptionNew context:MGSArrangedObjectsContext];
	
	// bind it
	// note that we must bind to the array controller as it is observed for changes in arranged objects.
	// so our trick of overriding - setValue:forKeyPath: on our view controller super class doen't work here.
	[[_tableView tableColumnWithIdentifier:@"value"] bind:NSValueBinding toObject:_arrayController withKeyPath:@"arrangedObjects.value" options:nil]; 
	[[_tableView tableColumnWithIdentifier:@"initial"] bind:NSValueBinding toObject:_arrayController withKeyPath:@"arrangedObjects.isInitialValue" options:nil]; 

	// register for drag types
	[_tableView registerForDraggedTypes: [NSArray arrayWithObject:MyPrivateTableViewDataType] ];
}

/*
 
 is initial item called
 
 */
- (void)setIsInitialValue:(BOOL)isInitial forItem:(MGSListParameterItem *)item
{
	if (isInitial) {
		for (MGSListParameterItem *listItem in [_arrayController arrangedObjects]) {
			if (listItem != item) {
				[listItem setIsInitialValue:NO];
			} 
		}
	}
}

/*
 
 begin a drag operation
 
 */
- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
	#pragma unused(tv)
	
    // Copy the row numbers to the pasteboard.
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    [pboard declareTypes:[NSArray arrayWithObject:MyPrivateTableViewDataType] owner:self];
    [pboard setData:data forType:MyPrivateTableViewDataType];
    return YES;
}

/*
 
 validate the drag operation
 
 */

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op
{
	#pragma unused(tv)
	#pragma unused(info)
	#pragma unused(row)
	#pragma unused(op)
	
    // Add code here to validate the drop
    //NSLog(@"validate Drop");
    return NSDragOperationEvery;
}

/*
 
 accept drag drop
 
 */
- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info
			  row:(int)row dropOperation:(NSTableViewDropOperation)operation
{
	#pragma unused(aTableView)
	#pragma unused(operation)
	
    NSPasteboard* pboard = [info draggingPasteboard];
    NSData* rowData = [pboard dataForType:MyPrivateTableViewDataType];
    NSIndexSet* rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
    int dragRow = [rowIndexes firstIndex];
	
    // Move the specified row to its new location...
	NSDragOperation dragOp = [info draggingSourceOperationMask];
	if ((dragOp & NSDragOperationMove) == NSDragOperationMove) {
		id dragItem = [[_arrayController arrangedObjects] objectAtIndex:dragRow];
		[_arrayController removeObjectAtArrangedObjectIndex:dragRow];
		if (dragRow < row) row--;
		[_arrayController insertObject:dragItem atArrangedObjectIndex:row];
	}
	
	return YES;
}
/*
 
 observe value for key path
 
 */
- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
	#pragma unused(keyPath)
	#pragma unused(change)
	
	BOOL enableRemove;
	
	if (context == MGSSelectedObjectsContext) {
		if (object == _arrayController) {
			NSArray *array = [_arrayController selectedObjects];
			if ([array count] > 0) {
				enableRemove = YES;
			} else {
				enableRemove = NO;
			}
			[_segmentedControl setEnabled:enableRemove forSegment:MGSRemoveItem];
		}
	}
	
	else if (context == MGSArrangedObjectsContext) {
	}
}


/*
 
 process item segment control action
 
 */
- (IBAction)segmentClick:(id)sender
{	
	#pragma unused(sender)
	
	int selectedSegment = [_segmentedControl selectedSegment];
	
	[_arrayController commitEditing];
	
	
	switch (selectedSegment) {
			
		// add item
		case MGSAddItem:;
			MGSListParameterItem *listItem = [[MGSListParameterItem alloc] init];
			listItem.value = NSLocalizedString(@"List item", @"List item");
			listItem.delegate = self;
			
			if (0 == [[_arrayController arrangedObjects] count]) {
				listItem.isInitialValue = YES;
			}
			// insert at selected position
			NSInteger selectionIndex = [_arrayController selectionIndex];
			if (NSNotFound == selectionIndex) {
				[_arrayController addObject:listItem];
			} else {
				[_arrayController insertObject:listItem atArrangedObjectIndex:selectionIndex+1];
			}

			
			//[self setRemoveSegmentEnabledState];
			NSInteger rowIndex = [_arrayController selectionIndex];
			[_tableView scrollRowToVisible:rowIndex];							// scroll row visible
			[_tableView editColumn:1 row:rowIndex withEvent:nil select:YES];	// edit cell
			break;
			
		// remove item
		case MGSRemoveItem:;
			NSArray *selectedObjects = [_arrayController selectedObjects];
			if ([selectedObjects count] > 0) {
				[_arrayController removeObject:[selectedObjects objectAtIndex:0]];
			}
			//[self setRemoveSegmentEnabledState];
			break;
			
			default:
			return;
	}
	
	self.modelDataModified = YES;
	
	return;
}

/*
 
 update plist
 
 */
- (void)updatePlist
{
	NSString *initialValue = @"";
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:1];
	for (MGSListParameterItem *listItem in [_arrayController arrangedObjects]) {
		[array addObject:listItem.value];
		if (listItem.isInitialValue) {
			initialValue = listItem.value;
		}
	}	
	[self setDefaultValue:initialValue];
	[self.plist setObject:array forKey:MGSKeyList];
}

/*
 
 initialise from plist
 
 */
- (void)initialiseFromPlist
{
	NSString *initialValue = [self.plist objectForKey:MGSScriptKeyDefault withDefault:@""];
	NSArray *array = [self.plist objectForKey:MGSKeyList withDefault:[[NSArray alloc] init]];
	BOOL initialised = NO;
	for (id item in array) {
		MGSListParameterItem *listItem = [_arrayController newObject];
		listItem.value = item;
		listItem.delegate = self;
		if ([initialValue isEqualToString:[listItem value]] && !initialised) {
			listItem.isInitialValue = YES;
			initialised = YES;
		}
		[_arrayController  addObject:listItem];
	}
}

@end
