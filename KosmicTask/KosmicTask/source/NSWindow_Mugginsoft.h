//
//  NSWindow_Mugginsoft.h
//  Mother
//
//  Created by Jonathan on 24/07/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSWindow (Mugginsoft)
- (BOOL)endEditing:(BOOL)force;
- (NSImageView*) addIconToTitleBar:(NSImage*) icon;
- (float) titleBarHeight;
- (float) toolbarHeight;
- (void)addViewToTitleBar:(NSView*)view xoffset:(CGFloat)xoffset;
- (NSRect)standardWindowRightButtonFrame:(NSView **)superview;
- (float) minimalWindowHeight;
@end
