//
//  MGSResultWindowController.h
//  Mother
//
//  Created by Jonathan on 15/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSToolbarController.h"

@class MGSResultViewController;
@class MGSResult;
@class MGSResultWindowController;
@class MGSToolbarController;
@class MGSPopupButton;

@protocol MGSResultWindow

@optional
- (void)resultWindowWillClose:(MGSResultWindowController *)resultWindowController;

@required
@end

@protocol MGSResultWindowDelegate
@required
- (MGSResultViewController *)activeResultViewController;
@end

@interface MGSResultWindowController : NSWindowController  <MGSToolbarDelegate, NSWindowDelegate, MGSResultWindowDelegate> {
	IBOutlet NSView *view;
	MGSResultViewController *_resultViewController;
	id _delegate;
	MGSToolbarController *_toolbarController;
}

- (void)setResult:(MGSResult *)aResult;
- (void)setDelegate:(id <MGSResultWindow>) object;
@end
