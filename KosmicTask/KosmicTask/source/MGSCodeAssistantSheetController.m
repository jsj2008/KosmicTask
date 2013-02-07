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

char MGSFunctionNameContext;

// class extension
@interface MGSCodeAssistantSheetController ()
- (void)closeSheet:(NSInteger)returnCode;
- (void)generateFunctionCodeString;
- (void)copySelectionToPasteBoard;

@property (copy, readwrite) NSArray *scriptTypes;
@property MGSLanguageCodeDescriptor *languageCodeDescriptor;

@end

@implementation MGSCodeAssistantSheetController

@synthesize scriptTypes = _scriptTypes;
@synthesize scriptType = _scriptType;
@synthesize languageCodeDescriptor = _languageCodeDescriptor;
@synthesize script = _script;

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
    
    // bind the segmented control
    [_codeSegmentedControl bind:NSSelectedTagBinding toObject:self withKeyPath:@"languageCodeDescriptor.descriptorCodeStyle" options:nil];
    
    // add observers
    [self addObserver:self forKeyPath:@"scriptType" options:0 context:&MGSFunctionNameContext];
    [self addObserver:self forKeyPath:@"languageCodeDescriptor.functionArgumentName" options:0 context:&MGSFunctionNameContext];
    [self addObserver:self forKeyPath:@"languageCodeDescriptor.functionArgumentCase" options:0 context:&MGSFunctionNameContext];
    [self addObserver:self forKeyPath:@"languageCodeDescriptor.functionArgumentStyle" options:0 context:&MGSFunctionNameContext];
    [self addObserver:self forKeyPath:@"languageCodeDescriptor.descriptorCodeStyle" options:0 context:&MGSFunctionNameContext];
    
    [self generateFunctionCodeString];
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
	[_fragaria setObject:_scriptType forKey:MGSFOSyntaxDefinitionName];
    if (self.script.scriptType != _scriptType) {
        self.script.scriptType = _scriptType;
    }
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

