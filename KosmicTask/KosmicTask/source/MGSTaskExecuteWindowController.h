//
//  MGSTaskExecuteWindowController.h
//  Mother
//
//  Created by Jonathan on 20/09/2009.
//  Copyright 2009 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSActionExecuteWindowController.h"
#import "MGSToolbarController.h"

@class MGSRequestViewController;
@class MGSToolbarController;

@interface MGSTaskExecuteWindowController : MGSActionExecuteWindowController <MGSToolbarDelegate, NSWindowDelegate>
{
	@public
	id delegate;
	
	@private
	MGSRequestViewController *requestViewController;
	MGSToolbarController *_toolbarController;
	MGSToolbarStyle _toolbarStyle;
	BOOL _terminateSheetDisplayed;
	BOOL _closeWhenTaskFinishes;
}

@property MGSRequestViewController *requestViewController;
@property MGSToolbarController *toolbarController;
@property MGSToolbarStyle toolbarStyle;


- (void)executeSelectedTask:(NSNotification *)notification;
- (void)terminateSelectedTask:(NSNotification *)notification;
- (void)suspendSelectedTask:(NSNotification *)notification;
- (void)resumeSelectedTask:(NSNotification *)notification;
- (BOOL)notificationObjectIsWindow:(NSNotification *)notification;
- (void)requestViewActionWillChange:(MGSRequestViewController *)requestViewController;
- (void)requestViewActionDidChange:(MGSRequestViewController *)requestViewController;

@end
