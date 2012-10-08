//
//  MGSScriptViewController.m
//  Mother
//
//  Created by Jonathan on 22/02/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSScriptViewController.h"
#import "MGSTaskSpecifier.h"
#import "MGSClientRequestManager.h"
#import "MGSMotherModes.h"
#import "MGSClientNetRequest.h"
#import "MGSNetRequestPayload.h"
#import "MGSNotifications.h"
#import "MGSScript.h"
#import "MGSScriptCode.h"
#import "MGSScriptPlist.h"
#import "NoodleLineNumberView.h"
#import "NoodleLineNumberMarker.h"
#import "MarkerLineNumberView.h"
#import "NSTextView_Mugginsoft.h"
#import "NSView_Mugginsoft.h"
#import "MGSLanguagePlugin.h"
#import <MGSFragaria/MGSFragaria.h>

#define NO_REQUEST_OUTSTANDING ULONG_MAX


NSString *MGSScriptSubroutineContext = @"MGSScriptSubroutineContext";
NSString *MGSScriptTypeContext = @"MGSScriptTypeContext";
NSString *MGSScriptSourceContext = @"MGSScriptSourceContext";

// class extension
@interface MGSScriptViewController()
- (void)configureEditorForScript;
- (void)updateEditorSyntaxDefinition;
- (void)setString:(NSString *)text;
- (void)textDidChange:(NSNotification *)aNotification;
- (void)setAttributedString:(NSAttributedString *)source;

- (BOOL)setRTFData:(NSData *)source;
- (void)setString:(NSString *)text;

@property BOOL scriptTextChanged;

@end

@interface MGSScriptViewController(Private)
- (void)requestTaskSource;
@end

@implementation MGSScriptViewController
@synthesize taskSpec = _taskSpec;
@synthesize delegate = _delegate;
@synthesize scriptTextChanged = _scriptTextChanged;
@synthesize scriptTemplateSource = _scriptTemplateSource;

#pragma mark -
#pragma mark Instance 
/*
 
 init
 
 */
- (id)init
{
	if ((self = [super initWithNibName:@"ScriptView" bundle:nil])) {
		_scriptTextChanged = NO;
		
	}
	return self;
}


/*
 
 awake from nib
 
 */
- (void)awakeFromNib
{
	// configure as public mode access
	_editMode = kMGSMotherRunModePublic;
	_currentHostView = _noScriptHostView;
	_currentTextView = nil;
	_stringHasBeenSet = NO;
	[_currentHostView setFrame:[[self view] frame]];
	[[self view] addSubview:_currentHostView];
	
	ignoreScriptSourceChange = NO;
	_requestID = NO_REQUEST_OUTSTANDING;
	
	// OSA script view
	MarkerLineNumberView *lineNumberView = [[MarkerLineNumberView alloc] initWithScrollView:_osaScrollView];
	[lineNumberView setBackgroundColor:[NSColor colorWithCalibratedWhite: 0.85f alpha: 1.0f]];
    [_osaScrollView setVerticalRulerView:lineNumberView];
    [_osaScrollView setHasHorizontalRuler:NO];
    [_osaScrollView setHasVerticalRuler:YES];
    [_osaScrollView setRulersVisible:YES];
	
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
	
    // turn off auto text replacement for items such as ...
    // as it can cause certain scripts to fail to build e.g: Python
    [_fragariaTextView setAutomaticDataDetectionEnabled:NO];
	[_fragariaTextView setAutomaticTextReplacementEnabled:NO];
     
	if (_delegate && [_delegate respondsToSelector:@selector(scriptViewLoaded:)]) {
		[_delegate scriptViewLoaded:self];
	}
	
}

/*
 
 dispose
 
 */
- (void)dispose
{
	// under 10.6 notifications are automatically removed when an object is finalised
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -
#pragma mark Responder
/*
 
 make first responder
 
 */
- (void)makeFirstResponder:(NSResponder *)responder
{
	#pragma unused(responder)
	
	[[[self view] window] makeFirstResponder:_currentTextView];
}

/*
 
 initial first responder
 
 */
- (NSView *)initialFirstResponder
{
	return _currentTextView;
}

#pragma mark -
#pragma mark MGSView delegate

/*
 
 - view:didMoveToWindow:
 
 */
- (void)view:(NSView *)aView didMoveToWindow:(NSWindow *)aWindow
{
	// if our view has been added to a window and there is a task spec pending then utilise it
	if (aView == [self view] && aWindow && _pendingTaskSpec) {
		[self setTaskSpec:_pendingTaskSpec];
		_pendingTaskSpec = nil;
	}
}

#pragma mark -
#pragma mark Task handling
/*
 
 - setTaskSpec
 
 */
- (void)setTaskSpec:(MGSTaskSpecifier *)aTaskSpec
{
	// if our view is not visible then cache the task spec
	if (![[self view] window]) {
		_pendingTaskSpec = aTaskSpec;
		return;
	}
	
	// remove previous observers
	if (_taskScript) {
		
		// on 10.6 observers are removed automatically when the object is finalised.
		// in this case we copy the incoming taskSpec so cleanup will be automatic.
		// not so however on 10.5
		@try {
			[_taskScript removeObserver:self forKeyPath:@"scriptCode.source"];
			[_taskScript removeObserver:self forKeyPath:@"scriptType"];
		} 
		@catch (NSException *e) {
			MLog(RELEASELOG, @"%@", [e reason]);
		}
		_taskScript = nil;
	}
	
	_requestID = NO_REQUEST_OUTSTANDING;
	
    
	// just keep a reference to the task spec.
	// the reference is shared between various views each of which may update it
	_taskSpec = aTaskSpec;	

    if (!_taskSpec) {
        return;
    }

    _scriptType = [[_taskSpec script] scriptType];
	
	// configure the editor
	[self configureEditorForScript];
		
	/*
	 
	 new task
	 
	 a new task won't have been persisted
	 
	 */
	if (_taskSpec.taskStatus == MGSTaskStatusNew) {
		
		// a new task may have its source predefined
		NSString *source = [[[_taskSpec script] scriptCode] source];
		if (source && [source length] > 0) {
			[self setAttributedString:[[NSAttributedString alloc] initWithString:source]];
		}
	}
	else {
		
		// get task source
		if (_editMode != kMGSMotherRunModePublic) {
			
			MGSScript *script = [_taskSpec script];
			NSData *sourceRTFData = [[script scriptCode] rtfSource];
			
			if (sourceRTFData) {
				[self setRTFData:sourceRTFData];
			} else {
				
				// request task source
				[self requestTaskSource];
			}
		}
	}
	
	// observe script properties
	_taskScript = [_taskSpec script];
	[_taskScript addObserver:self forKeyPath:@"scriptType" options:0 context:MGSScriptTypeContext];
	[_taskScript addObserver:self forKeyPath:@"scriptCode.source" options:0 context:MGSScriptSourceContext];
}



#pragma mark -
#pragma mark KVO
/*
 
 observe value for keypath
 
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	#pragma unused(keyPath)
	#pragma unused(object)
	#pragma unused(change)
	
	if (context == MGSScriptTypeContext) {
		
		[self configureEditorForScript];
				
	} else if (context == MGSScriptSourceContext) {
		
		if (!ignoreScriptSourceChange) {
		
			NSString *source = [[[_taskSpec script] scriptCode] source];
            NSAttributedString *sourceFromBuild = [[[_taskSpec script] scriptCode] attributedSourceFromBuild];
            
			if (source && [source length] > 0) {

                // if the build provided attributed source (as in the case of AppleScript)
                // thenn use it directly
                if (sourceFromBuild) {
                    [self setAttributedString:sourceFromBuild];
                    
                    // we can discard the build source
                    [[[_taskSpec script] scriptCode] setAttributedSourceFromBuild:nil];
                } else {
                    [self setString:source];
                }

				// the source has been updated so send a text change notification
				[self textDidChange:nil];

			}
		}
	}
}

#pragma mark -
#pragma mark Printing
/*
 
 print
 
 */
- (void)printDocument:(id)sender
{
	#pragma unused(sender)
	
	[_currentTextView print:self];
}

/*
 
 document printable
 
 */
- (BOOL)documentPrintable
{
	// cannot print if no superview
	if (![[self view] superview]) return NO;
	 
	return YES;
}

#pragma mark -
#pragma mark Source handling

/*
 
 -setSelectedRange:
 
 */
- (void)setSelectedRange:(NSRange)range
{
	[self setSelectedRange:range options:nil];
}
/*
 
 -setSelectedRange:
 
 */
- (void)setSelectedRange:(NSRange)range options:(NSDictionary *)options
{
    NSArray *ranges = [NSArray arrayWithObject:[NSValue valueWithRange:range]];
	[self setSelectedRanges:ranges options:options];
}
/*
 
 -setSelectedRanges:
 
 */
- (void)setSelectedRanges:(NSArray *)ranges 
{
    [self setSelectedRanges:ranges options:nil];
}
/*
 
 -setSelectedRanges:options
 
 */
- (void)setSelectedRanges:(NSArray *)ranges options:(NSDictionary *)options
{
	@try {
		[_currentTextView setSelectedRanges:ranges];
        
        BOOL scrollVisible = [[options objectForKey:@"scrollVisible"] boolValue];
        if (scrollVisible) {
            NSRange range = [[ranges objectAtIndex:0] rangeValue];
            [_currentTextView scrollRangeToVisible:range];
        }
	}
	@catch (NSException * e) {
		MLog(DEBUGLOG, @"%@", [e name]);
	}
}
/*
 
 - setRTFData:
 
 */
- (BOOL)setRTFData:(NSData *)sourceScript
{
	
	_requestID = NO_REQUEST_OUTSTANDING;
	
	if (sourceScript && [sourceScript length] == 0) {
		sourceScript = nil;
	}
	
	if (sourceScript == nil) {
		[self setString:@""];
		return NO;
	}

	// get source string from data
	NSMutableAttributedString *source = [[NSMutableAttributedString alloc] initWithRTF:sourceScript documentAttributes:nil];
	[self applyDefaultFormatting:source];
	[self setAttributedString:source];
	
	return YES;
}

/*
 
 - setAttributedString:
 
 */
- (void)setAttributedString:(NSAttributedString *)source
{
	NSTextView *textView = _currentTextView;
	if (source != nil) {
		
        BOOL undo = NO;
        if (_stringHasBeenSet) {
            undo = YES;
        }
        
		if (_currentTextView == _fragariaTextView) {
			
            if ([_fragaria isSyntaxColoured]) {
                // regardless of the original source markup we want the
                // text view to apply its own syntax colouring
                [self setString:[source string]];
            } else {
                
                // use the attributed string as is.
                // in the case of AppleScript it will include syntac colouring
                [_fragaria setAttributedString:source options:[NSDictionary dictionaryWithObjectsAndKeys:
                                                   [NSNumber numberWithBool:undo], @"undo",
                                                   nil]];
                
#ifdef MGS_CHANGE_FONT_IN_EDITOR
                // change the font of the attributed string to match
                // default Fragaria font.
                // this is required to keep the line numbering metrics right
                NSFont *font = [NSFont fontWithName:@"Menlo" size:11];
                [textView changeFont:font];
#endif
                [[textView undoManager] removeAllActions];
            }

		} else {
			[[textView textStorage] setAttributedString:source];
			[[textView undoManager] removeAllActions];
		}
            
        _stringHasBeenSet = YES;
	}	
}

/*
 
 - setString:
 
 */
- (void)setString:(NSString *)text
{
	if (!_currentTextView) {
		return;
	}
	
	// setString does not cause the textDidChange: notification to be sent
	// nor do we want it too as this causes setting the initial value to
	// be registered as an edit.
	// also setString does not register the action as undoable
	if (!_stringHasBeenSet) {
		[_currentTextView setString:text];
		_stringHasBeenSet = YES;
	} else {
		NSAssert(_currentTextView == _fragariaTextView, @"Fragaria text view expected");
		
		[_fragaria setString:text options:[NSDictionary dictionaryWithObjectsAndKeys:
										   [NSNumber numberWithBool:YES], @"undo",
										   nil]];
	}
}


/*
 
 - scriptSourceRTFData
 
 */
- (NSData *)scriptSourceRTFData
{
	NSAttributedString *scriptSource = [self scriptAttributedSource];
	NSRange range = NSMakeRange(0, [scriptSource length]);
	return [scriptSource RTFFromRange:range documentAttributes:nil];
}
/*
 
 - scriptAttributedSource
 
 */
- (NSAttributedString *)scriptAttributedSource
{
	// get attributed string.
    // if document is syntax coloured then we need to preserve the
    // document temporary attributes
	NSAttributedString *scriptSource = nil;;
    if ([_fragaria isSyntaxColoured]) {
        scriptSource = [_fragaria attributedStringWithTemporaryAttributesApplied];
    } else {
        
        // if the editor is not syntax colouring then the source
        // may have been coloured during the build, in which
        // case we simply want the attributed string as is
        scriptSource = [_fragaria attributedString];
    }
    
	if (NO) {
		NSLog(@"Att enum start");
		[scriptSource enumerateAttributesInRange: NSMakeRange(0, [scriptSource length])
											 options: NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
										  usingBlock: ^(NSDictionary *attributesDictionary,
														NSRange range,
														BOOL *stop)
		 {
	#pragma unused(range)
	#pragma unused(stop)
			 NSLog(@"Att dict = %@", attributesDictionary);
		 }];
		NSLog(@"Att enum end");
	}
	
	NSString *source = [scriptSource string];
	
	// some scripts require a trailing \n
	NSString *raw = [source stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	if ([raw length] > 0 && ![raw hasSuffix:@"\n"]) {
		NSMutableAttributedString *newScriptSource = [[NSMutableAttributedString alloc] initWithAttributedString:scriptSource];
		[newScriptSource appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
		scriptSource = newScriptSource;
	}
	
	return scriptSource;
}

/*
 
 - scriptSource
 
 */
- (NSString *)scriptSource
{
	return [[self scriptAttributedSource] string];
}

/*
 
 - shiftLeftAction:
 
 */
- (void)shiftLeftAction:(id)sender
{
#pragma unused(sender)
	[[_fragaria textMenuController] shiftLeftAction:self];
}

#pragma mark -
#pragma mark Font handling

/*
 
 - applyDefaultFormatting:
 
 */
- (void)applyDefaultFormatting:(NSMutableAttributedString *)attributedString
{
    // normalise the font name and size
    //NSFont *font = [NSFont fontWithName:@"Menlo" size:11];
    
    // Fragaria uses NSUserDefaultsController and passes in initial values.
    // These initial values are not available to NSUserDefaults so they
    // have to be initialised first.
    //id values = [[NSUserDefaultsController sharedUserDefaultsController] values];
    //NSFont *font = [NSUnarchiver unarchiveObjectWithData:[values valueForKey:MGSFragariaPrefsTextFont]];

    NSData *fontData = [[NSUserDefaults standardUserDefaults] objectForKey:MGSFragariaPrefsTextFont];
    NSFont *font = [NSUnarchiver unarchiveObjectWithData:fontData];
    [attributedString changeFont:font];
}
#pragma mark -
#pragma mark Edit behaviour
/*
 
 set editable
 
 */
- (void)setEditable:(BOOL)editable
{
	_editable = editable;
	if (_currentTextView) {
		[_currentTextView setEditable:editable];
	}
}

/*
 
 set the edit mode
 
 note: may be called when _taskSpec is nil
 */
- (void)setEditMode:(NSInteger)mode
{	
	if (_editMode == mode) {
		return;
	}
	_editMode = mode;
	
	switch (_editMode) {
			
		// don't display script source
		case kMGSMotherRunModePublic:
			[self setRTFData:nil];
			break; 
			
		// retrieve and display source
		case kMGSMotherRunModeConfigure:
		case kMGSMotherRunModeAuthenticatedUser:
			[self requestTaskSource];			
		break;
			
		default:
			NSAssert(NO, @"invalid edit mode");
			break;
	}

	[self configureEditorForScript];
}

/*
 
 - configureEditorForScript
 
 */
- (void)configureEditorForScript
{
	if (!_taskSpec) {
		return;
	}
	
	NSView *displayView = nil;
	
	switch (_editMode) {
			
			// don't display script source
		case kMGSMotherRunModePublic:
			_currentTextView = nil;
			displayView = _noScriptHostView;
			break; 
			
			// retrieve and display source
		case kMGSMotherRunModeConfigure:
		case kMGSMotherRunModeAuthenticatedUser:;	
			NSTextView *prevTextView = _currentTextView;
			
			// select appropriate NSTextView
#ifdef MGS_USE_OSA_EDITOR
            MGSLanguagePlugin *languagePlugin = [[_taskSpec script] languagePlugin];
            if ([languagePlugin isOSALanguage]) {
                _currentTextView = _osaTextView;
                displayView = _osaHostView;
            } else {
                _currentTextView = _fragariaTextView;
                displayView = _fragariaHostView;
            }
        
#else
			_currentTextView = _fragariaTextView;
			displayView = _fragariaHostView;
#endif
	
			[_currentTextView setEditable:_editable];
			 
			// very strange but failing to test for prevTextView != nil
			// here causes authentication to fail!
			// error saving to keychain.
			if (prevTextView != _currentTextView && prevTextView) {
				NSString *text = [prevTextView string];
				[_currentTextView setString:text];
			}
			
			break;
			
		default:
			NSAssert(NO, @"invalid edit mode");
			break;
	}
	
	// at present we leave the script as is rather
	// than prompting the user
	if (NO) {
		[self setString:@""];
	}
	
	// show reqd view if not already displayed
	if (displayView != _currentHostView) {
		[[self view] replaceSubview:_currentHostView withViewFrameAsOld:displayView];
		_currentHostView = displayView;
	}
	
	// configure for script syntax
	[self updateEditorSyntaxDefinition];
}

/*
 
 - updateEditorSyntaxDefinition
 
 */
- (void)updateEditorSyntaxDefinition
{
	if (_currentTextView == _fragariaTextView) {
		MGSLanguagePlugin *languagePlugin = [[_taskSpec script] languagePlugin];
		[_fragaria setObject:[languagePlugin syntaxDefinition] forKey:MGSFOSyntaxDefinitionName];
        
        // if the language build returns RTF then we don't want Fragaria to
        // syntax highlight
        BOOL syntaxColoured = !([languagePlugin buildResultFlags] & kMGSScriptSourceRTF);
        [_fragaria setSyntaxColoured:syntaxColoured];
	}
}

#pragma mark -
#pragma mark Undo management

/*
 
 - undoManager
 
 */
- (NSUndoManager *)undoManager
{
	return [_currentTextView undoManager];
}

#pragma mark -
#pragma mark MGSNetRequest owner messages
/*
 
 net request response
 
 */
-(void)netRequestResponse:(MGSClientNetRequest *)netRequest payload:(MGSNetRequestPayload *)payload
{
	
	NSString *requestCommand = netRequest.kosmicTaskCommand;
	
	// validate response
	if (NSOrderedSame != [requestCommand caseInsensitiveCompare:MGSScriptCommandGetScriptUUIDCompiledSource]) {
		[MGSError clientCode:MGSErrorCodeInvalidCommandReply reason: [NSString stringWithFormat:@"expected: %@ received: %@", MGSScriptCommandGetScriptUUIDCompiledSource, requestCommand]];
	}
	
	// if no request outstanding then this data must represent a previous request.
	// this data is no longer required.
	if (_requestID == NO_REQUEST_OUTSTANDING) {
		return;
	}
	
	// data for a previous request has arrived while waiting for current request.
	// this data is no longer required
	if (_requestID != payload.requestID) {
		return;
	}
	
	// get rtfdata source if available - generally it should not
	NSData *rtfData =[[payload dictionary] objectForKey:MGSScriptKeyCompiledScriptSourceRTF];
	if (rtfData && [rtfData isKindOfClass:[NSData class]]) {
		[self setRTFData:rtfData];
		return;
	}
	
	// get string source - should be available
	NSString *source =[[payload dictionary] objectForKey:MGSScriptKeyScriptSource];
	if (source && [source isKindOfClass:[NSString class]]) {
		[[[_taskSpec script] scriptCode] setSource:source];
		return;
	}
	
	
	MLogInfo(@"source missing from request payload");
}

/*
 
 net request update
 
 */
-(void)netRequestUpdate:(MGSNetRequest *)netRequest
{
	#pragma unused(netRequest)
}


#pragma mark -
#pragma mark NSTextView delegate
/*
 
 - textDidChange:
 
 */
- (void)textDidChange:(NSNotification *)aNotification
{
	#pragma unused(aNotification)
		
	if (!self.scriptTextChanged) {
		self.scriptTextChanged = YES;
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteScriptTextChanged object:[[self view] window] userInfo:nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteViewModelEdited object:[[self view] window] userInfo:nil];

}

/*
 
 - textDidEndEditing:
 
 */
- (void)textDidEndEditing:(NSNotification *)aNotification
{
#pragma unused(aNotification)
	
	/*
	 
	generally this notification is sent but
	if the text is edited and the view is swapped for another subview
	then it may not get sent!
	 
	*/
	
	if (self.scriptTextChanged) {
		NSAttributedString *scriptSource = [self scriptAttributedSource];	
		MGSScript *script = [_taskSpec script]; 
		
		if (!scriptSource) {
			scriptSource = [[NSAttributedString alloc] initWithString:@""];
		}
		ignoreScriptSourceChange = YES;
		[[script scriptCode] setAttributedSource:scriptSource];
		ignoreScriptSourceChange = NO;
		
		self.scriptTextChanged = NO;
	}
}

@end

@implementation MGSScriptViewController(Private)

/*
 
 - requestTaskSource
 
 */
- (void)requestTaskSource
{
	_requestID = NO_REQUEST_OUTSTANDING;

	// check if we have the source already
	NSString *source = [[[_taskSpec script] scriptCode] source];
	if (source) {
		return;
	}
	
	// clear the textview while we wait for source
	[self setString:@""];

	if (_taskSpec == nil) {
		return;
	}
		
	// we must have at least a display representation before we request the source.
	// eg: we don't want to request the source for a preview representation as it will
	// only get replaced by a display rep which will then request its own source.
	if (![[_taskSpec script] canConformToRepresentation:MGSScriptRepresentationDisplay]) {
		return;
	}
	
	// if script exists on server then try and retrieve source
	if ([_taskSpec.script scriptStatus] == MGSScriptStatusExistsOnServer) {
		
		// create a mutable deep copy as a new instance.
		// we may issue a request for the script source code in which
		// case we will need a separate copy so that the progress, elapsed time etc
		// of the request can be maintained.
		MGSTaskSpecifier *taskCopy = [_taskSpec mutableDeepCopyAsNewInstance];
		taskCopy.taskStatus = _taskSpec.taskStatus; // required
				
		[[MGSClientRequestManager sharedController] requestCompiledScriptSourceForTask:taskCopy withOwner:self];
		
		// if we generated a net request then cache the most recent id.
		// we will only display scripts that match the most recent id.
		if (taskCopy.netRequest) {
			_requestID = taskCopy.netRequest.requestID;
		} 
	} 
}

@end

