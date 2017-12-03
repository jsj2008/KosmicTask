//
//  MGSRequestViewController.h
//  Mother
//
//  Created by Jonathan on 01/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSClientNetRequest.h"
#import "MGSMotherModes.h"

@class MGSNetClient;
@class MGSBrowserViewController;
@class MGSInputRequestViewController;
@class MGSOutputRequestViewController;
@class MGSScript;
@class MGSRequestViewController;
@class MGSWaitViewController;
@class MGSTaskSpecifier;
@class MGSActionActivityView;
@class MGSNetRequest;

@protocol MGSRequestViewControllerDelegate
@required

@end

@interface MGSRequestViewController : NSViewController <MGSNetRequestOwner> {
	NSView *_requestView;
	
	IBOutlet NSSplitView *splitView;
	IBOutlet NSView *leftView;
	IBOutlet NSView *rightView;
	IBOutlet MGSInputRequestViewController *_inputViewController;
	IBOutlet MGSOutputRequestViewController *_outputViewController;
	IBOutlet NSView *__weak _emptyRequestView;
	IBOutlet MGSActionActivityView *_actionActivityView;
	IBOutlet NSTextField *_emptyRequestViewTextField;
	
	BOOL _nibLoaded;
	BOOL _sendCompletedActionSpecifierToHistory;
	
	MGSWaitViewController *_waitViewController;
	id __weak _delegate;
	NSInteger _viewEffect;	// effect to use when showing views
	
	NSImage                 *_icon;			// icon
    NSString                *_iconName;		// icon name
    NSObjectController      *controller;
    int                     _objectCount;
	BOOL _observesInputModifications;
	BOOL haveAutomatedKeepActionDisplayed;
	MGSClientNetRequest *displayNetRequest;
}

- (IBAction)executeScript:(id)sender;
- (IBAction)terminateScript:(id)sender;
- (IBAction)suspendScript:(id)sender;
- (IBAction)resumeScript:(id)sender;

- (BOOL)isProcessing;
//- (void)setIsProcessing:(BOOL)value;
- (NSImage *)icon;
- (void)setIcon:(NSImage *)icon;
- (NSString *)iconName;
- (void)setIconName:(NSString *)iconName;
- (int)objectCount;
- (void)setObjectCount:(int)value;
- (NSObjectController *)controller;
- (void)dispose;
- (BOOL)keepActionDisplayed;
- (BOOL)permitSetActionSpecifier;
- (void)actionInputModified;
- (MGSTaskSpecifier *)actionSpecifier;
- (void)setActionSpecifier:(MGSTaskSpecifier *)actionSpec;
- (void)syncPartnerSelectedIndex:(id)sender;
- (BOOL)shouldResizeWithSizeDelta:(NSSize)oldBoundsSize;
- (CGFloat)minViewWidth;
- (void)toggleViewMode:(eMGSMotherViewConfig)mode;

// properties
@property (weak, nonatomic) id delegate;
@property (readonly) NSInteger viewEffect;
@property (weak, readonly) NSView *emptyRequestView;
@property (readonly) MGSInputRequestViewController *inputViewController;
@property (readonly) MGSOutputRequestViewController *outputViewController;
@property (nonatomic) BOOL observesInputModifications;
@property BOOL sendCompletedActionSpecifierToHistory;
@end
