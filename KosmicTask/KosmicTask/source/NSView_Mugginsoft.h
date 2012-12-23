//
//  NSView_Mugginsoft.h
//  Mother
//
//  Created by Jonathan on 12/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

enum tagNSView_Animate {
	NSView_animateEffectNone = 0,
    NSView_animateEffectFade,
};
typedef NSInteger NSView_animate;

@interface NSView (Mugginsoft)
- (void)replaceSubview:(NSView *)oldView with:(NSView *)newView withEffect:(NSView_animate)effect;
- (IBAction)setHidden:(BOOL)hidden withFade:(BOOL)fade;
- (void)replaceSubview:(NSView *)oldView withViewSizedAsOld:(NSView *)newView;
- (void)resizeAndAddSubviewBeneath:(NSView *)subView;
- (void)resizeAndRemoveSubviewBeneath:(NSView *)subView;
- (void)setControlsEnabled:(BOOL)enabled retainState:(BOOL)retainState recurseSubviews:(BOOL)recurse;
- (void)setControlsEnabled:(BOOL)enabled;
- (void)replaceSubview:(NSView *)oldView withViewFrameAsOld:(NSView *)newView;
- (NSImage *)mgs_captureImage;
- (NSImageView *)mgs_captureImageView;
- (void)mgs_fadeToSiblingView:(NSView *)view duration:(NSTimeInterval)duration;
- (NSImage *)mgs_dragImage;
@end

