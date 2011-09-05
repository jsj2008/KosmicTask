//
//  MGSPath.h
//  Mother
//
//  Created by Jonathan on 21/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//extern NSString *MGSUserApplicationSupportPath;
//extern NSString *MGSApplicationSupportPath;


@interface MGSPath : NSObject {

}

// bundle paths (work for both client and agent)
+ (NSString *)executablePath;
+ (NSString *)bundleContentPath;
+ (NSString *)bundleResourcePath;
+ (NSString *)bundleHelperPath;
+ (NSString *)bundlePluginPath;
+ (NSString *)bundlePath;
+ (NSString *)bundlePathForHelperExecutable:(NSString *)execName;

// user document path
+ (NSString *)userDocumentPath;
+ (BOOL)userDocumentPathExists;
+ (NSString *)verifyUserDocumentPath;

// application document path
+ (NSString *)applicationDocumentPath;
+ (BOOL)applicationDocumentPathExists;
+ (NSString *)verifyApplicationDocumentPath;

// user application support path
+ (NSString *)userApplicationSupportPath;
+ (BOOL)userApplicationSupportPathExists;
+ (NSString *)verifyUserApplicationSupportPath;

+ (NSString *)hostNameMinusLocalLink:(NSString *)hostName;
+ (NSDictionary *)userFileAttributes;
+ (NSString *)createFolder:(NSString *)folder withAttributes:(NSDictionary *)attributes;

+ (NSString *)validateFilenameCharacters:(NSString *)filename;

+ (NSDictionary *)adminFileAttributes;
@end
 
