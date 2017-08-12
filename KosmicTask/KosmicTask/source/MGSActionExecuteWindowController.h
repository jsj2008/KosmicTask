//
//  MGSActionExecuteWindowController.h
//  Mother
//
//  Created by Jonathan on 02/09/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSActionExecuteWindow.h"
#import "MGSResultWindowController.h"
#import "MGSOpenPanelController.h"

@class MGSTaskSpecifier;
@class MGSNetClient;
@class MGSResultViewController;
@class MGSRequestViewController;
@class MGSOpenPanelController;

@interface MGSActionExecuteWindowController : NSWindowController <MGSActionExecuteWindowDelegate,
																MGSResultWindowDelegate, 
																MGSOpenPanelControllerDelegate
																> {
	@private
	IBOutlet MGSActionExecuteWindow *__weak _actionExecuteWindow;
	MGSNetClient *__weak _netClient;
	MGSOpenPanelController *_openPanelController;
}

@property (weak) MGSActionExecuteWindow *actionExecuteWindow;
@property (weak) MGSNetClient *netClient;
@property (readonly) MGSOpenPanelController *openPanelController;

- (MGSTaskSpecifier *)selectedActionSpecifier;
- (void)showNetClientSecurityStateInTitleBar;
- (void)removeClientObservers;
- (void)windowWillClose:(NSNotification *)note;
- (MGSResultViewController *)activeResultViewController;
- (MGSRequestViewController *)activeRequestViewController;

- (IBAction)openFile:(id)sender;
- (IBAction)newDocument:(id)sender;
- (IBAction)openTaskInNewWindow:(id)sender;
- (IBAction)openResultInNewWindow:(id)sender;

- (IBAction)requestExecuteTask:(id)sender;
- (IBAction)requestSuspendTask:(id)sender;
- (IBAction)requestResumeTask:(id)sender;
- (IBAction)requestTerminateTask:(id)sender;
- (IBAction)requestEditTask:(id)sender;

- (void)openPanelControllerDidClose:(NSNotification *)notification;

@end
