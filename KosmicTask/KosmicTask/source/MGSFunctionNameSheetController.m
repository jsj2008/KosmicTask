//
//  MGSFunctionNameSheetController.m
//  KosmicTask
//
//  Created by Jonathan on 06/01/2013.
//
//

#import "MGSFunctionNameSheetController.h"
#import <MGSFragaria/MGSFragaria.h>
#import "MGSScript.h"

char MGSFunctionNameContext;

// class extension
@interface MGSFunctionNameSheetController ()
- (void)closeSheet:(NSInteger)returnCode;
- (void)generateFunctionCodeString;

@property (copy, readwrite) NSArray *scriptTypes;
@property MGSFunctionArgumentName functionArgumentName;
@property MGSFunctionArgumentCase functionArgumentCase;
@property MGSFunctionArgumentStyle functionArgumentStyle;
@property MGSFunctionCodeStyle functionCodeStyle;

@end

@implementation MGSFunctionNameSheetController

@synthesize scriptTypes = _scriptTypes;
@synthesize scriptType = _scriptType;
@synthesize functionArgumentName = _functionArgumentName;
@synthesize functionArgumentCase = _functionArgumentCase;
@synthesize functionArgumentStyle = _functionArgumentStyle;
@synthesize functionCodeStyle = _functionCodeStyle;

/*
 
 - init
 
 */
- (id)init
{
	self = [super init];
	if (self) {
		self = [super initWithWindowNibName:@"FunctionNameSheet"];
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
    
    _functionArgumentName = kMGSFunctionArgumentName;
    _functionArgumentCase = kMGSFunctionArgumentCamelCase;
    _functionArgumentStyle = kMGSFunctionArgumentWhitespaceRemoved;
    
    // bind the argument tags
    [_argumentNamePopupButton bind:NSSelectedTagBinding toObject:self withKeyPath:@"functionArgumentName" options:nil];
    [_argumentCasePopupButton bind:NSSelectedTagBinding toObject:self withKeyPath:@"functionArgumentCase" options:nil];
    [_argumentStylePopupButton bind:NSSelectedTagBinding toObject:self withKeyPath:@"functionArgumentStyle" options:nil];
    
    // bind the segmented control
    _functionCodeStyle = kMGSFunctionCodeInputOnly;
    [_codeSegmentedControl bind:NSSelectedTagBinding toObject:self withKeyPath:@"functionCodeStyle" options:nil];
    
    // add observers
    [self addObserver:self forKeyPath:@"scriptType" options:0 context:&MGSFunctionNameContext];
    [self addObserver:self forKeyPath:@"functionArgumentName" options:0 context:&MGSFunctionNameContext];
    [self addObserver:self forKeyPath:@"functionArgumentCase" options:0 context:&MGSFunctionNameContext];
    [self addObserver:self forKeyPath:@"functionArgumentStyle" options:0 context:&MGSFunctionNameContext];
    [self addObserver:self forKeyPath:@"functionCodeStyle" options:0 context:&MGSFunctionNameContext];
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
#pragma mark Code generation
/*
 
 - generateFunctionCodeString
 
 */
- (void)generateFunctionCodeString
{
    NSString *functionString = @"KosmicTask (blah)";
    
    _fragaria.string = functionString;
}

/*
 
 - setScriptType:
 
 */

- (void)setScriptType:(NSString *)name
{
    _scriptType = name;
	[_fragaria setObject:_scriptType forKey:MGSFOSyntaxDefinitionName];
}

#pragma mark -
#pragma mark Actions

/*
 
 - ok:
 
 */
- (IBAction)ok:(id)sender
{
#pragma unused(sender)
	
	[self closeSheet:1];
}

/*
 
 - copyToPasteBoard;
 
 */
- (IBAction)copyToPasteBoard:(id)sender
{
#pragma unused(sender)
	
#ifdef MGS_FUNCTION_PASTE_RTF_DATA
    
	NSAttributedString *attString = [_fragaria attributedString];
	NSData *data = [attString RTFFromRange:NSMakeRange(0, [attString length]) documentAttributes:nil];
	NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
	[pasteboard clearContents];
	[pasteboard setData:data forType:NSRTFPboardType];
    
#else
    NSString *text = [_fragaria string];
	//NSData *data = [attString RTFFromRange:NSMakeRange(0, [attString length]) documentAttributes:nil];
	NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
	[pasteboard clearContents];
	[pasteboard setString:text forType:NSStringPboardType];
    
#endif
}

/*
 
 - closeSheet:
 
 */
- (void)closeSheet:(NSInteger)returnCode
{
	[[self window] orderOut:self];
	[NSApp endSheet:[self window] returnCode:returnCode];
}
@end

