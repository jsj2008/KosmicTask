//
//  MGSPlugin.h
//  Mother
//
//  Created by Jonathan on 21/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MGSPlugin : NSObject {

}

// shared instance
//+ (id)sharedInstance;

// Returns the version of the interface you're implementing.
// Return 0 here or future versions may look for features you don't have!
- (unsigned)interfaceVersion;

// Returns what to display in a menu.
- (NSString *)menuItemString;

// called on exception
- (void)onException:(NSException *)e;

// is default plugin
- (BOOL)isDefault;


@end
