//
//  KosmicTaskHelperAppDelegate.m
//  KosmicTaskHelper
//
//  Created by Jonathan on 09/06/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "KosmicTaskHelperAppDelegate.h"

@interface KosmicTaskHelperAppDelegate (MGSScriptability)
- (NSString *)tempFilePath;
@end

@implementation KosmicTaskHelperAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
}

@end

@implementation KosmicTaskHelperAppDelegate (MGSScriptability)
/*
 
 application:delegateHandlesKey:
 
 */
- (BOOL)application:(NSApplication *)sender delegateHandlesKey:(NSString *)key
{
    if ([key isEqual:@"tempfile"]) {
        return YES;
    } else {
        return NO;
    }
}

/*
 
 - tempFilePath
 
 */
- (NSString *)tempFilePath
{
	return [@"xxx" copy];
}

@end
