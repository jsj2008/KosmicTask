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
	NSString *appParentPath = [[self appPackagePath] stringByAppendingPathComponent:@".."];
	return [appParentPath stringByStandardizingPath];
}

/*
 
 application package path
 
 */
+ (NSString *)appPackagePath
{
	NSString *appPath = [[self toolPath] stringByAppendingPathComponent:@"../.."];
	return [appPath stringByStandardizingPath];
}

/*
 
 tool path
 
 */
+ (NSString *)toolPath
{
	NSString *path = [MGSPath bundleHelperPath];
	return path;
}


@end


