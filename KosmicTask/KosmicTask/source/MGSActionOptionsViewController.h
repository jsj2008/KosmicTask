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
	IBOutlet NSTextField *_timeout;
	IBOutlet NSStepper *_timeoutStepper;
	IBOutlet NSButton *_useTimeoutButton;
	
	MGSTaskSpecifier *_actionSpecifier;
	BOOL _useTimeout;
}


@property MGSTaskSpecifier *actionSpecifier;
@property BOOL useTimeout;
@end
