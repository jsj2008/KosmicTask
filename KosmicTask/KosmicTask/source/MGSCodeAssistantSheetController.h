//
//  MGSCodeAssistantSheetController.h
//  KosmicTask
//
//  Created by Jonathan on 06/01/2013.
//
//

#import <Cocoa/Cocoa.h>
#import  "MGSLanguageCodeDescriptor.h"

@class MGSFragaria;
@class MGSLanguageCodeDescriptor;
@class MGSScript;
@class PSMTabBarControl;
@class MGSBorderView;
@class MGSTaskVariablesViewController;

enum {
  kMGSCodeAssistantSheetReturnOk,
  kMGSCodeAssistantSheetReturnCopy,
  kMGSCodeAssistantSheetReturnInsert,
  kMGSCodeAssistantSheetReturnShowTemplate,
  kMGSCodeAssistantSheetReturnShowFile,
  kMGSCodeAssistantSheetReturnShowRunSettings,
};
typedef NSInteger MGSCodeAssistantSheetReturnValue;

enum {
    MGSCodeAssistantSelectionTaskBody = 0,
    MGSCodeAssistantSelectionTaskInputs = 1,
    MGSCodeAssistantSelectionTaskVariables = 2,
};
typedef NSInteger MGSCodeAssistantCodeSelection;

@interface MGSCodeAssistantSheetController : NSWindowController
{
    IBOutlet NSPopUpButton *_scriptTypePopupButton;
    IBOutlet NSPopUpButton *_argumentNamePopupButton;
    IBOutlet NSPopUpButton *_argumentCasePopupButton;
    IBOutlet NSPopUpButton *_argumentStylePopupButton;
    IBOutlet NSTextField *_runConfigurationTextField;
    IBOutlet PSMTabBarControl *tabBar;
    IBOutlet NSTextField *_argumentPrefix;
    IBOutlet NSTextView *_argumentNameExclusions;
    IBOutlet NSButton *_copyButton;
    IBOutlet NSButton *_insertButton;
    IBOutlet NSTextField *_inputTotalTextField;
    IBOutlet NSTextField *_inputAutoTextField;
    IBOutlet NSTextField *_inputManualTextField;
    IBOutlet NSButton *_inputAutoAllButton;
    
    NSView *_selectedTabView;
    
    MGSLanguageCodeDescriptor *_languageCodeDescriptor;
    MGSTaskVariablesViewController *_taskVariablesViewController;
    
    MGSScript *_script;
    MGSFragaria *_fragaria;
    IBOutlet MGSBorderView *_borderView;
	IBOutlet NSView *_fragariaHostView; // fragria host view
	NSTextView *_fragariaTextView;
    NSArray *_scriptTypes;
    BOOL _showInfoTextImage;
    NSString *_infoText;
    MGSCodeAssistantCodeSelection _codeSelection;
    BOOL _canInsert;
    BOOL _autoAllEnabled;
    
    NSInteger _inputVariableTotal;
    NSInteger _inputVariableAuto;
    NSInteger _inputVariableManual;
}

- (IBAction)ok:(id)sender;
- (IBAction)copyToPasteBoardAction:(id)sender;
- (IBAction)showRunSettings:(id)sender;
- (IBAction)openTemplateSheetAction:(id)sender;
- (IBAction)insertCodeAction:(id)sender;
- (IBAction)openFileSheetAction:(id)sender;
- (IBAction)autoAllInputVariablesAction:(id)sender;

@property (copy, readonly) NSArray *scriptTypes;
@property MGSScript *script;
@property (copy) NSString *infoText;
@property MGSCodeAssistantCodeSelection codeSelection;
@property BOOL canInsert;
- (NSString *)codeString;
@property NSInteger inputVariableTotal;
@property NSInteger inputVariableAuto;
@property NSInteger inputVariableManual;
@property BOOL autoAllEnabled;

@end
