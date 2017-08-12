//
//  MGSActionDetailEditViewController.h
//  Mother
//
//  Created by Jonathan on 03/03/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MGSTaskSpecifier;


@interface MGSActionDetailEditViewController : NSViewController {
	IBOutlet NSView *__weak infoView;
	IBOutlet NSView *actionDetailView;
	IBOutlet NSScrollView *scrollView;
	IBOutlet NSPopUpButton *scriptType;
	IBOutlet NSTextField *__weak name;
	IBOutlet NSComboBox *group;
	IBOutlet NSButton *published;
	IBOutlet NSTextField *description;
	IBOutlet NSTextView *longDescription;
	IBOutlet NSTextField *author;
	IBOutlet NSTextField *authorNote;
	IBOutlet NSDatePicker *created;
	IBOutlet NSDatePicker *modified;
	IBOutlet NSButton *modifiedAuto;

	IBOutlet NSTextField *definitionCapsule;
	IBOutlet NSTextField *descriptionCapsule;
	IBOutlet NSTextField *optionsCapsule;
	IBOutlet NSTextField *infoCapsule;
	
	// version number
	IBOutlet NSTextField *versionMajorText;
	IBOutlet NSStepper *versionMajorStepper;
	IBOutlet NSTextField *versionMinorText;
	IBOutlet NSStepper *versionMinorStepper;
	IBOutlet NSTextField *versionRevisionText;
	IBOutlet NSStepper *versionRevisionStepper;
	IBOutlet NSButton *versionRevisionAuto;
	
	// options
	IBOutlet NSStepper *timeoutStepper;
	IBOutlet NSTextField *timeout;
	IBOutlet NSButton *useTimeoutButton;
    IBOutlet NSPopUpButton *timeoutUnitsPopUp;
    
	IBOutlet NSPopUpButton *userInteractionMode;
	
	MGSTaskSpecifier *__weak _action;
    NSObjectController *_objectController;
}

- (void)setAction:(MGSTaskSpecifier *)anAction;

- (IBAction)toggleFontPanel:(id)sender;
- (IBAction)toggleColorPanel:(id)sender;
- (IBAction)refreshCreatedDate:(id)sender;
- (IBAction)refreshModifiedDate:(id)sender;
- (IBAction)defaultScriptType:(id)sender;

@property (weak) MGSTaskSpecifier *action;
@property (weak) NSTextField *nameTextField;
@property (weak, readonly) NSView *infoView;

@end
