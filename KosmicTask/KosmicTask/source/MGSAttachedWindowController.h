//
//  MGSAttachedWindowController.h
//  Mother
//
//  Created by Jonathan on 25/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/CoreAnimation.h>

@class MAAttachedWindow;
@class MGSAttachedViewController;

@interface MGSAttachedWindowController : NSObject {
	MGSAttachedViewController *_attachedViewController;
    MAAttachedWindow *_attachedWindow;
	NSWindow *_parentWindow;
	BOOL _applyTimeout;
	NSTimer *_timer;
	NSTimeInterval _timerInterval;
}

+ (id)sharedController;
- (void)showForWindow:(NSWindow *)aWindow atCentreOfRect:(NSRect)rect withText:(NSString *)text ;
- (void)showForWindow:(NSWindow *)aWindow atPoint:(NSPoint)aPoint;
- (BOOL)hide;
- (void)hideNow;

@end
