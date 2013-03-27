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

char MGSInputArgumentContext;
char MGSScriptTypeContext;

// class extension
@interface MGSCodeAssistantSheetController ()
- (void)closeSheet:(NSInteger)returnCode;
- (void)generateCodeString;
- (void)copySelectionToPasteBoard;
- (void)configureTabBar;
- (void)scriptTypeChanged;

@property (copy, readwrite) NSArray *scriptTypes;
@property MGSLanguageCodeDescriptor *languageCodeDescriptor;
@property BOOL showInfoTextImage;

@end

@implementation MGSCodeAssistantSheetController

@synthesize scriptTypes = _scriptTypes;
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
    
    // bind script type content values
	[_scriptTypePopupButton bind:@"contentValues" toObject:self withKeyPath:@"scriptTypes" options:nil];
    
    _languageCodeDescriptor = [[MGSLanguageCodeDescriptor alloc] init];

    // add observers
    [self addObserver:self forKeyPath:@"languageCodeDescriptor.descriptorCodeStyle" options:0 context:&MGSInputArgumentContext];
    
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
    if (_script) {

        // unbind the argument tags
        [_scriptTypePopupButton unbind:NSSelectedValueBinding];
        [_argumentNamePopupButton unbind:NSSelectedTagBinding];
        [_argumentCasePopupButton unbind:NSSelectedTagBinding];
        [_argumentStylePopupButton unbind:NSSelectedTagBinding];
        [_argumentPrefix unbind:NSValueBinding];
        [_argumentNameExclusions unbind:NSValueBinding];
        
        // remove observers
        [_script removeObserver:self forKeyPath:@"scriptType"];
        [_script removeObserver:self forKeyPath:@"inputArgumentName"];
        [_script removeObserver:self forKeyPath:@"inputArgumentCase"];
        [_script removeObserver:self forKeyPath:@"inputArgumentStyle"];
        [_script removeObserver:self forKeyPath:@"inputArgumentPrefix"];
        [_script removeObserver:self forKeyPath:@"inputArgumentNameExclusions"];
        
        _script = nil;
    }
    if (!script) return;
    
    _script = [script mutableDeepCopy];

    // bind the argument tags
    [_scriptTypePopupButton bind:NSSelectedValueBinding toObject:_script withKeyPath:@"scriptType" options:nil];
    [_argumentNamePopupButton bind:NSSelectedTagBinding toObject:_script withKeyPath:@"inputArgumentName" options:nil];
    [_argumentCasePopupButton bind:NSSelectedTagBinding toObject:_script withKeyPath:@"inputArgumentCase" options:nil];
    [_argumentStylePopupButton bind:NSSelectedTagBinding toObject:_script withKeyPath:@"inputArgumentStyle" options:nil];
    [_argumentPrefix bind:NSValueBinding toObject:_script withKeyPath:@"inputArgumentPrefix" options:@{ NSContinuouslyUpdatesValueBindingOption : @(YES)}];
    [_argumentNameExclusions bind:NSValueBinding toObject:_script withKeyPath:@"inputArgumentNameExclusions" options:@{NSContinuouslyUpdatesValueBindingOption : @(YES)}];
    
    // add observers
    [_script addObserver:self forKeyPath:@"scriptType" options:0 context:&MGSScriptTypeContext];
    [_script addObserver:self forKeyPath:@"inputArgumentName" options:0 context:&MGSInputArgumentContext];
    [_script addObserver:self forKeyPath:@"inputArgumentCase" options:0 context:&MGSInputArgumentContext];
    [_script addObserver:self forKeyPath:@"inputArgumentStyle" options:0 context:&MGSInputArgumentContext];
    [_script addObserver:self forKeyPath:@"inputArgumentPrefix" options:0 context:&MGSInputArgumentContext];
    [_script addObserver:self forKeyPath:@"inputArgumentNameExclusions" options:0 context:&MGSInputArgumentContext];
    
    [self scriptTypeChanged];
    [self generateCodeString];
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
    
	if (context == &MGSInputArgumentContext) {
        [self generateCodeString];
    } else if (context == &MGSScriptTypeContext) {
        [self scriptTypeChanged];
        [self generateCodeString];
    }
    
}

#pragma mark -
#pragma mark Text selection handling
/*
 
 - copySelectionToPasteBoard
 
 */
- (void)copySelectionToPasteBoard
{
    // use general pasteboard for cut and paste
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    
    // clear the existing contents
    [pasteboard clearContents];
    
    // define array to hold pasteboard objects
    NSMutableArray *representations = [NSMutableArray arrayWithCapacity:3];
    
    // add plain text representation
    NSString *text = [_fragaria string];
    if (text) {
        [representations addObject:text];
    }
    
    // property list
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:10];
    if (dict && text) {
        
        // build custom data dictionary
        
        // script type
        [dict setObject:self.script.scriptType forKey:@"scriptType"];
        
        // input argument properties
        [dict setObject:@(self.script.inputArgumentName) forKey:@"inputArgumentName"];
        [dict setObject:@(self.script.inputArgumentCase) forKey:@"inputArgumentCase"];
        [dict setObject:@(self.script.inputArgumentStyle) forKey:@"inputArgumentStyle"];
        [dict setObject:self.script.inputArgumentPrefix forKey:@"inputArgumentPrefix"];
        [dict setObject:self.script.inputArgumentNameExclusions forKey:@"inputArgumentNameExclusions"];
                
        // add pasteboatd item with custom data identified by custom UTI
        NSString *templateUTI = @"com.mugginsoft.kosmictask.codeassistant.template";
        NSPasteboardItem *pbItem = [[NSPasteboardItem alloc] init];
        if ([pbItem setPropertyList:dict forType:templateUTI]) {
            [representations addObject:pbItem];
        } else {
            NSLog(@"NSPasteboardItem property list not set for UTI: %@", templateUTI);
        }
    }
    
    // write objects to the pasteboard
    [pasteboard writeObjects:representations];
}

#pragma mark -
#pragma mark Code generation
/*
 
 - generateCodeString
 
 */
- (void)generateCodeString
{
    // setup the descriptor
    [self.languageCodeDescriptor setScript:self.script];

    // generate code string
    NSString *functionString = [self.languageCodeDescriptor generateCodeString];
    if (!functionString) {
        functionString = NSLocalizedString(@"[Code generation failed. See the log for details.]", @"Missing language function code");
    }
    _fragaria.string = functionString;
}

/*
 
 - scriptTypeChanged
 
 */

- (void)scriptTypeChanged
{
    // get language
    MGSLanguagePlugin *languagePlugin = [self.script languagePlugin];
    MGSLanguage *language = languagePlugin.language;
            
    // configure Fragaria syntax highlighting
    [_fragaria setObject:[languagePlugin syntaxDefinition] forKey:MGSFOSyntaxDefinitionName];
    
    // enable allowed argument styles
    NSArray *menuTags = @[ @(kMGSInputArgumentUnderscoreSeparated), @(kMGSInputArgumentWhitespaceRemoved)];
    NSMenuItem *menuItem = nil;
    for (NSNumber *tag in menuTags) {
        menuItem = [[_argumentStylePopupButton menu] itemWithTag:[tag integerValue]];
        BOOL hidden = YES;
        if (language.initInputArgumentStyleAllowedFlags & [tag integerValue]) {
            hidden = NO;
        }
        [menuItem setHidden:hidden];
    }
    
    // display on run task
    NSInteger onRunTask = [_script onRun].integerValue;
    [_runConfigurationTextField setStringValue:[_script.languagePropertyManager stringForOnRunTask:onRunTask]];
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

