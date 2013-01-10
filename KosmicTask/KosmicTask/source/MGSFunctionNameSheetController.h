//
//  MGSFunctionNameSheetController.h
//  KosmicTask
//
//  Created by Jonathan on 06/01/2013.
//
//

#import <Cocoa/Cocoa.h>
#import  "MGSLanguageFunctionDescriptor.h"

@class MGSFragaria;
@class MGSLanguageFunctionDescriptor;
@class MGSScript;

@interface MGSFunctionNameSheetController : NSWindowController
{
    IBOutlet NSPopUpButton *_scriptTypePopupButton;
    IBOutlet NSPopUpButton *_argumentNamePopupButton;
    IBOutlet NSPopUpButton *_argumentCasePopupButton;
    IBOutlet NSPopUpButton *_argumentStylePopupButton;
    IBOutlet NSSegmentedControl *_codeSegmentedControl;
    IBOutlet NSTextField *_runConfigurationTextField;
    
    MGSLanguageFunctionDescriptor *_functionDescriptor;
    
    MGSScript *_script;
    MGSFragaria *_fragaria;
	IBOutlet NSView *_fragariaHostView; // fragria host view
	NSTextView *_fragariaTextView;
    NSArray *_scriptTypes;
    NSString *_scriptType;
}

- (IBAction)ok:(id)sender;
- (IBAction)copyToPasteBoard:(id)sender;
- (IBAction)showRunSettings:(id)sender;
- (IBAction)selectTemplate:(id)sender;
- (IBAction)insertCode:(id)sender;

@property (copy, readonly) NSArray *scriptTypes;
@property (copy) NSString *scriptType;
@property MGSScript *script;

@end
