//
//  MGSExportPlugin.h
//  Mother
//
//  Created by Jonathan on 19/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSPlugin.h"

@protocol MGSExportPlugin
@optional;

// export attributed string
- (NSString *)exportAttributedString:(NSAttributedString *)aString toPath:(NSString *)path;

// export string
- (NSString *)exportString:(NSString *)aString toPath:(NSString *)path;

// export plist
- (NSString *)exportPlist:(id)aPlist toPath:(NSString *)path;

// export view
- (NSString *)exportView:(NSView *)aView toPath:(NSString *)path;

// Returns what to display in a display menu.
- (NSString *)displayMenuItemString;

// export plist as data
- (NSData *)exportPlistAsData:(id)aPlist;

@end

@interface MGSExportPlugin : MGSPlugin <MGSExportPlugin> {
}


// open file
- (BOOL)openFileWithDefaultApplication:(NSString *)fullPath;
- (void)onException:(NSException *)e path:(NSString *)path;
- (NSString *)fileExtension;
- (NSString *)completePath:(NSString *)aPath;
- (void)onError:(NSError *)anError;
- (void)onErrorString:(NSString *)anError;
- (BOOL)isDisplayDefault;

@end
