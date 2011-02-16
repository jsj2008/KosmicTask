//
//  MGSLanguageResourcesWindowController.h
//  KosmicTask
//
//  Created by Jonathan on 12/06/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSResourceBrowserViewController.h"

@interface MGSResourceBrowserWindowController : NSWindowController {
	MGSResourceBrowserViewController *resourceBrowserViewController;
	BOOL nibLoaded;
}

+ (id)sharedController;
- (BOOL)resolveURL:(NSString *)url;
@end
