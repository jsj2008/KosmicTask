//
//  MGSMotherWindowSplitview.h
//  Mother
//
//  Created by Jonathan on 13/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class CATransition;
@class CAAnimation;
@interface MGSMainSplitview : NSSplitView {
	CATransition *_transition;
}
- (void)updateSubviewsTransition;
- (void)replaceTopView:(NSView *)newView;
- (void)replaceMiddleView:(NSView *)newView;
- (void)replaceBottomView:(NSView *)newView;
- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag;
@end
