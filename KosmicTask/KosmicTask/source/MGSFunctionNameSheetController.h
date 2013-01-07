//
//  MGSFunctionNameSheetController.h
//  KosmicTask
//
//  Created by Jonathan on 06/01/2013.
//
//

#import <Cocoa/Cocoa.h>

enum _MGSFunctionArgumentName {
    kMGSFunctionArgumentName = 0,
    kMGSFunctionArgumentNameAndType = 1,
    kMGSFunctionArgumentType = 2,
    kMGSFunctionArgumentTypeAndName = 3,
};
typedef NSUInteger MGSFunctionArgumentName;

enum _MGSFunctionArgumentCase {
    kMGSFunctionArgumentCamelCase= 0,
    kMGSFunctionArgumentLowerCase = 1,
    kMGSFunctionArgumentInputCase = 2,
    kMGSFunctionArgumentPascalCase = 3,
    kMGSFunctionArgumentUpperCase = 4,
};
typedef NSUInteger MGSFunctionArgumentCase;

enum _MGSFunctionArgumentStyle {
    kMGSFunctionArgumentHyphenated = 0,
    kMGSFunctionArgumentUnderscoreSeparated = 1,
    kMGSFunctionArgumentWhitespaceRemoved = 2,
};
typedef NSUInteger MGSFunctionArgumentStyle;

enum _MGSFunctionCodeStyle {
    kMGSFunctionCodeInputOnly = 0,
    kMGSFunctionCodeFuntionBody = 1,
};
typedef NSUInteger MGSFunctionCodeStyle;

@class MGSFragaria;

@interface MGSFunctionNameSheetController : NSWindowController
{
    IBOutlet NSPopUpButton *_scriptTypePopupButton;
    IBOutlet NSPopUpButton *_argumentNamePopupButton;
    IBOutlet NSPopUpButton *_argumentCasePopupButton;
    IBOutlet NSPopUpButton *_argumentStylePopupButton;
    IBOutlet NSSegmentedControl *_codeSegmentedControl;
    
    MGSFunctionArgumentName _functionArgumentName;
    MGSFunctionArgumentCase _functionArgumentCase;
    MGSFunctionArgumentStyle _functionArgumentStyle;
    MGSFunctionCodeStyle _functionCodeStyle;
    
    MGSFragaria *_fragaria;
	IBOutlet NSView *_fragariaHostView; // fragria host view
	NSTextView *_fragariaTextView;
    NSArray *_scriptTypes;
    NSString *_scriptType;
}

- (IBAction)ok:(id)sender;
- (IBAction)copyToPasteBoard:(id)sender;

@property (copy, readonly) NSArray *scriptTypes;
@property (copy) NSString *scriptType;

@end
