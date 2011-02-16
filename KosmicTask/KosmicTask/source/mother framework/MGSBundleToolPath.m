//
//  MGSBundleToolPath.m
//  Mother
//
//  Created by Jonathan on 06/12/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSBundleToolPath.h"
#import "MGSMother.h"

@implementation MGSBundleToolPath

/*
 
 application package enclosing folder
 
 */
+ (NSString *)appPackageParentPath
{
	NSString *appParentPath = [[self appPackagePath] stringByAppendingPathComponent:@".."];;
	return [appParentPath stringByStandardizingPath];
}

/*
 
 application package path
 
 */
+ (NSString *)appPackagePath
{
	// for a bundled foundation tool [[NSBundle mainBundle] bundlePath] gives bundle folder
	// so we go up from 
	// Shared Support to Contents
	// Contents to <app name>.app
	NSString *appPath = [[self toolPath] stringByAppendingPathComponent:@"../.."];
	return [appPath stringByStandardizingPath];
}

/*
 
 tool path
 
 */
+ (NSString *)toolPath
{
	// for a bundled foundation tool in Content/MacOS [[NSBundle mainBundle] bundlePath] gives bundle folder.
	// note that moving the tool around in the bundle is not advisable
	// as it may cause problems with locating thr tool.
	NSString *path = [[NSBundle mainBundle] bundlePath];
	path = [[self toolPath] stringByAppendingPathComponent:@"Contents/MacOS"];
	MLog(DEBUGLOG, @"Foundation tool bundle path: %@", path);
	return path;
}


@end


