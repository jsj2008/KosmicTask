//
//  MGSDebugHandler.h
//  mother
//
//  Created by Jonathan Mitchell on 13/10/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MGSDebugHandler : NSObject {

}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;
- (void)enableDebugLogging: (BOOL)enable;
- (void)enableCoreDumps: (BOOL)enable;
@end
