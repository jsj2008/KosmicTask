//
//  MGSActionActivityViewController.h
//  Mother
//
//  Created by Jonathan on 16/07/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSActionActivityView.h"


@interface MGSActionActivityViewController : NSViewController <MGSActionActivityViewDelegate> {
	IBOutlet MGSActionActivityView *_activityView;
	IBOutlet NSTextField *_activityTextField;
	IBOutlet NSImageView *_dragThumbImage;
	
	MGSTaskActivity _activity;
	NSTimer *_animationTimer;
	
}


@property MGSTaskActivity activity;

- (void)animate:(NSTimer *)aTimer;
- (void)updateAnimation;
- (NSView *)splitViewAdditionalView;
- (void)setRunMode:(eMGSMotherRunMode)mode;

@end
