//
//  MGSActionOptionsViewController.h
//  Mother
//
//  Created by Jonathan on 30/07/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MGSTaskSpecifier;

@interface MGSActionOptionsViewController : NSViewController {
	IBOutlet NSTextField *_timeoutField;
	IBOutlet NSStepper *_timeoutStepper;
	IBOutlet NSButton *_useTimeoutButton;
	IBOutlet NSPopUpButton *_timeoutUnitsPopUp;
    
    NSObjectController *_scriptController;
    
	MGSTaskSpecifier *_actionSpecifier;
	BOOL _useTimeout;
    NSUInteger _timeout;
    NSUInteger _timeoutUnits;
}


@property MGSTaskSpecifier *actionSpecifier;
@property BOOL useTimeout;
@property NSUInteger timeout;
@property NSUInteger timeoutUnits;
@end
