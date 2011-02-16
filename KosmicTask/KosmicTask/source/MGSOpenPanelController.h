//
//  MGSOpenPanelController.h
//  KosmicTask
//
//  Created by Jonathan on 25/10/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSOpenSourceFileAccessoryViewController.h"

@class MGSOpenSourceFileAccessoryViewController;
@class MGSOpenPanelController;

@protocol MGSOpenPanelControllerDelegate <NSObject>
@required
- (void)openPanelControllerDidClose:(NSNotification *)note;
@end

@interface MGSOpenPanelController : NSObject <NSOpenSavePanelDelegate> {
	MGSOpenSourceFileAccessoryViewController *_openSourceFileAccessoryViewController;
	NSWindow *window;
	id <MGSOpenPanelControllerDelegate> delegate;
}

- (NSOpenPanel *)openSourceFile:(id)theSender options:(NSDictionary *)options;

@end
