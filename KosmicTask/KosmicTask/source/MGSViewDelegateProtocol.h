/*
 *  MGSViewDelegateProtocol.h
 *  KosmicTask
 *
 *  Created by Jonathan on 30/12/2009.
 *  Copyright 2009 mugginsoft.com. All rights reserved.
 *
 */
@protocol MGSViewDelegateProtocol <NSObject>
@optional
- (void)view:(NSView *)aView didMoveToWindow:(NSWindow *)aWindow;
- (void)viewDidMoveToSuperview:(NSView *)aView;
@end

