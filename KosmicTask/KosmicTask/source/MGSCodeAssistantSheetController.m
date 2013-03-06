//
//  MGSCodeAssistantSheetController.m
//  KosmicTask
//
//  Created by Jonathan on 06/01/2013.
//
//

#import "MGSCodeAssistantSheetController.h"
#import <MGSFragaria/MGSFragaria.h>
#import "MGSScript.h"
#import "MGSLanguagePluginController.h"
#import <PSMTabBarControl/PSMTabBarControl.h>
#import <PSMTabBarControl/PSMTabStyle.h>
#import "MGSTabViewItemModel.h"
#import "MGSKosmicCardTabStyle.h"
#import "MGSKosmicUnityTabStyle2.h"
#import "MGSBorderView.h"

char MGSFunctionNameContext;

// class extension
@interface MGSCodeAssistantSheetController ()
- (void)closeSheet:(NSInteger)returnCode;
- (void)generateFunctionCodeString;
- (void)copySelectionToPasteBoard;
- (void)configureTabBar;

@property (copy, readwrite) NSArray *scriptTypes;
@property MGSLanguageCodeDescriptor *languageCodeDescriptor;
@property BOOL showInfoTextImage;

@end

@implementation MGSCodeAssistantSheetController

@synthesize scriptTypes = _scriptTypes;
@synthesize scriptType = _scriptType;
@synthesize languageCodeDescriptor = _languageCodeDescriptor;
@synthesize script = _script;
@synthesize showInfoTextImage = _showInfoTextImage;
@synthesize infoText = _infoText;

/*
 
 - init
 
 */
- (id)init
{
	self = [super init];
	if (self) {
		self = [super initWithWindowNibName:@"CodeAssistant"];
	}
	
	return self;
}

/*
 
 - awakeFromNib
 
 */
- (void)awakeFromNib
{
    // create Fragaria instance
	_fragaria = [[MGSFragaria alloc] init];
	
	//
	// define initial object configuration
	//
	// see MGSFragaria.h for details
	//
	[_fragaria setObject:[NSNumber numberWithBool:YES] forKey:MGSFOIsSyntaxColoured];
	[_fragaria setObject:[NSNumber numberWithBool:YES] forKey:MGSFOShowLineNumberGutter];
	[_fragaria setObject:self forKey:MGSFODelegate];
	
	// embed in out host view
	[_fragaria embedInView:_fragariaHostView];
	_fragariaTextView = [_fragaria objectForKey:ro_MGSFOTextView];
	self.window.initialFirstResponder = _fragariaTextView;
    
    // turn off auto text replacement for items such as ...
    // as it can cause certain scripts to fail to build e.g: Python
    [_fragariaTextView setAutomaticDataDetectionEnabled:NO];
	[_fragariaTextView setAutomaticTextReplacementEnabled:NO];
    
    _scriptTypes = [MGSScript validScriptTypes];
    _scriptType = @"AppleScript";
    
    // bind script type content values
	[_scriptTypePopupButton bind:@"contentValues" toObject:self withKeyPath:@"scriptTypes" options:nil];
	[_scriptTypePopupButton bind:NSSelectedValueBinding toObject:self withKeyPath:@"scriptType" options:nil];
    
    _languageCodeDescriptor = [[MGSLanguageCodeDescriptor alloc] init];

    // bind the argument tags
    [_argumentNamePopupButton bind:NSSelectedTagBinding toObject:self withKeyPath:@"languageCodeDescriptor.functionArgumentName" options:nil];
    [_argumentCasePopupButton bind:NSSelectedTagBinding toObject:self withKeyPath:@"languageCodeDescriptor.functionArgumentCase" options:nil];
    [_argumentStylePopupButton bind:NSSelectedTagBinding toObject:self withKeyPath:@"languageCodeDescriptor.functionArgumentStyle" options:nil];
    
    // add observers
    [self addObserver:self forKeyPath:@"scriptType" options:0 context:&MGSFunctionNameContext];
    [self addObserver:self forKeyPath:@"languageCodeDescriptor.functionArgumentName" options:0 context:&MGSFunctionNameContext];
    [self addObserver:self forKeyPath:@"languageCodeDescriptor.functionArgumentCase" options:0 context:&MGSFunctionNameContext];
    [self addObserver:self forKeyPath:@"languageCodeDescriptor.functionArgumentStyle" options:0 context:&MGSFunctionNameContext];
    [self addObserver:self forKeyPath:@"languageCodeDescriptor.descriptorCodeStyle" options:0 context:&MGSFunctionNameContext];
    
    [self generateFunctionCodeString];
    
    // configure tab bar
    [self configureTabBar];
    
}

#pragma mark -
#pragma mark TabBar configuration and delegate methods

/*
 
 - configureTabBar
 
 */
- (void)configureTabBar
{
    [[tabBar class] registerTabStyleClass:[MGSKosmicUnityTabStyle2 class]];
    [[tabBar class] registerTabStyleClass:[MGSKosmicCardTabStyle class]];
    
    // we don't host our views in an NSTabView instance but tabBar requires one
    NSTabView *tabView = [[NSTabView alloc] initWithFrame:_fragariaHostView.frame];
    tabView.delegate = (id)tabBar;
    tabBar.tabView = tabView;
    
    // remove any tabs present in the nib
    for (NSTabViewItem *item in [tabView tabViewItems]) {
		[tabView removeTabViewItem:item];
	}
    
    // configure tab bar
	MGSTabViewItemModel *newModel = [[MGSTabViewItemModel alloc] init];
	NSTabViewItem *newItem = [(NSTabViewItem*)[NSTabViewItem alloc] initWithIdentifier:newModel];
	[newItem setLabel:@"Task Body"];
	[tabBar.tabView addTabViewItem:newItem];
    
    newModel = [[MGSTabViewItemModel alloc] init];
	newItem = [(NSTabViewItem*)[NSTabViewItem alloc] initWithIdentifier:newModel];
	[newItem setLabel:@"Task Inputs"];
	[tabBar.tabView addTabViewItem:newItem];
    
    [tabBar setStyleNamed:[MGSKosmicUnityTabStyle2 name]];
    [tabBar setDisableTabClose:YES];
    [tabBar setCellMinWidth:80];
    [tabBar setCellOptimumWidth:100];
    
    if (NO) {
        NSView *borderView = _fragariaHostView.superview;
        NSRect borderFrame = [borderView frame];
        NSRect tabFrame = [tabBar frame];
        CGFloat gutterWidth = [[NSUserDefaults standardUserDefaults] floatForKey:MGSFragariaPrefsGutterWidth];
        
        tabFrame.size.width = borderFrame.size.width - gutterWidth;
        tabFrame.origin.x =  borderFrame.origin.x + gutterWidth;
        [tabBar setFrame:tabFrame];
    }

    _borderView.borderFlags = (kMGSBorderViewTop | kMGSBorderViewBottom );
}

/*
 
 - tabView:didSelectTabViewItem:
 
 */
- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    NSInteger tabIndex = [aTabView indexOfTabViewItem:tabViewItem];
    
    if (tabIndex == 0) {
        self.languageCodeDescriptor.descriptorCodeStyle = kMGSCodeDescriptorTaskBody;
    } else {
        self.languageCodeDescriptor.descriptorCodeStyle = kMGSCodeDescriptorTaskInputs;
    }
}
#pragma mark -
#pragma mark Accessors

/*
 
 - setScript:
 
 */
- (void)setScript:(MGSScript *)script
{
    _script = script;
    self.scriptType = [_script scriptType];
}

/*
 
 - setInfoText:
 
 */
- (void)setInfoText:(NSString *)infoText
{
    infoText = [infoText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    _infoText =  infoText;
    
    if ([_infoText length] > 0) {
        self.showInfoTextImage = YES;
    } else {
        self.showInfoTextImage = NO;
    }
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
    
	if (context == &MGSFunctionNameContext) {
        [self generateFunctionCodeString];
    }
    
}

#pragma mark -
#pragma mark Text selection handling
/*
 
 - copySelectionToPasteBoard
 
 */
- (void)copySelectionToPasteBoard
{
	
#ifdef MGS_FUNCTION_PASTE_RTF_DATA
    
	NSAttributedString *attString = [_fragaria attributedString];
	NSData *data = [attString RTFFromRange:NSMakeRange(0, [attString length]) documentAttributes:nil];
	NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
	[pasteboard clearContents];
	[pasteboard setData:data forType:NSRTFPboardType];
    
#else
    NSRange selectedRange = [_fragariaTextView selectedRange];
    NSString *text = [_fragaria string];
    
    // if a valid selection range exists then use it
    if (NO && selectedRange.location != NSNotFound && selectedRange.length > 0) {
        text = [text substringWithRange:selectedRange];
    }
    
	NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
	[pasteboard clearContents];
	[pasteboard setString:text forType:NSStringPboardType];
    
#endif
    
}

#pragma mark -
#pragma mark Code generation
/*
 
 - generateFunctionCodeString
 
 */
- (void)generateFunctionCodeString
{
    NSString *functionString = nil;
    
    [self.languageCodeDescriptor setScript:self.script];
    functionString = [self.languageCodeDescriptor generateCodeString];
    
    if (!functionString) {
        functionString = NSLocalizedString(@"[Code generation failed. See the log for details.]", @"Missing language function code");
    }
    _fragaria.string = functionString;
}

/*
 
 - setScriptType:
 
 */

- (void)setScriptType:(NSString *)name
{
    _scriptType = name;
    
    if (self.script.scriptType != _scriptType) {
        self.script.scriptType = _scriptType;
    }
    MGSLanguagePlugin *languagePlugin = [self.script languagePlugin];
    [_fragaria setObject:[languagePlugin syntaxDefinition] forKey:MGSFOSyntaxDefinitionName];
}

#pragma mark -
#pragma mark Actions

/*
 
 - ok:
 
 */
- (IBAction)ok:(id)sender
{
#pragma unused(sender)
	
	[self closeSheet:kMGSCodeAssistantSheetReturnOk];
}

/*
 §
 - copyToPasteBoardAction;
 
 */
- (IBAction)copyToPasteBoardAction:(id)sender
{
#pragma unused(sender)
    [self copySelectionToPasteBoard];
    [self closeSheet:kMGSCodeAssistantSheetReturnCopy];
}

/*
 
 - closeSheet:
 
 */
- (void)closeSheet:(NSInteger)returnCode
{
	[[self window] orderOut:self];
	[NSApp endSheet:[self window] returnCode:returnCode];
}

/*
 
 - showRunSettings:
 
 */
- (IBAction)showRunSettings:(id)sender
{
#pragma unused(sender)
    
	[self closeSheet:kMGSCodeAssistantSheetReturnShowRunSettings];
}

/*
 
 - openTemplateSheetAction:
 
 */
- (IBAction)openTemplateSheetAction:(id)sender
{
#pragma unused(sender)
    
	[self closeSheet:kMGSCodeAssistantSheetReturnShowTemplate];
}

/*
 
 - openFileSheetAction:
 
 */
- (IBAction)openFileSheetAction:(id)sender
{
#pragma unused(sender)
    
	[self closeSheet:kMGSCodeAssistantSheetReturnShowFile];
}

/*
 
 - insertCode:
 
 */
- (IBAction)insertCodeAction:(id)sender
{
#pragma unused(sender)
    [self copySelectionToPasteBoard];
	[self closeSheet:kMGSCodeAssistantSheetReturnInsert];
}
@end

