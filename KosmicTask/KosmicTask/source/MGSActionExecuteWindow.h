//
//  MGSActionExecuteWindow.h
//  Mother
//
//  Created by Jonathan on 02/09/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MGSTaskSpecifier;

@protocol MGSActionExecuteWindowDelegate
- (MGSTaskSpecifier *)selectedActionSpecifier;
@end

@protocol MGSSubviewClicking
- (void)subviewClicked:(NSView *)aView ;
@end

@interface MGSActionExecuteWindow : NSWindow {
	NSImageView *_titleBarImageView;
	NSHashTable *_clickViews;
}

- (void)setTitleBarIcon:(NSImage *)image;
- (void)removeTitleBarIcon;
- (MGSTaskSpecifier *)selectedActionSpecifier;
- (void)addClickView:(NSView *)aView;
@end
