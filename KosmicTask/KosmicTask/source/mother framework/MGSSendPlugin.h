//
//  MGSSendPlugin.h
//  Mother
//
//  Created by Jonathan on 21/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSPlugin.h"

@protocol MGSSendPlugin
@optional;

// send string
- (BOOL)sendAttributedString:(NSAttributedString *)aString;

// send formatted string
- (BOOL)sendFormattedAttributedString:(NSAttributedString *)aString;

// send plist
- (BOOL)sendPlist:(id)aPlist;

@end

@interface MGSSendPlugin : MGSPlugin <MGSSendPlugin> {

}

- (NSString *)targetAppName;
- (NSString *)bundleIdentifier;
- (BOOL)targetAppInstalled;
- (void)copyToPasteboardAsRTF:(id)object;
- (BOOL)executeAppleScript:(NSString *)script;
- (BOOL)queueSelector:(SEL)selector withObject:(id)object;
- (BOOL)executeSend:(NSAttributedString *)aString;
@end
