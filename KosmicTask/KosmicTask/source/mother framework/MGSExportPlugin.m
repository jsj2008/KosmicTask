//
//  MGSExportPlugin.m
//  Mother
//
//  Created by Jonathan on 19/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSExportPlugin.h"
#import "MGSError.h"

@implementation MGSExportPlugin

/* 
 
 file extension
 
 */
- (NSString *)fileExtension
{
	return @"";
}

/*
 
 on exception
 
 */
- (void)onException:(NSException *)e path:(NSString *)path
{
	NSString *error = [NSString stringWithFormat: NSLocalizedString(@"Data could not be exported to: %@ : %@", @"Send plugin error string"), path, e];
	[MGSError clientCode:MGSErrorCodeExportPlugin reason:error];
}

/*
 
 on error
 
 */
- (void)onError:(NSError *)anError
{

	[MGSError clientCode:MGSErrorCodeExportPlugin userInfo:[anError userInfo]];
}

/*
 
 on error string
 
 */
- (void)onErrorString:(NSString *)anError
{
	
	[MGSError clientCode:MGSErrorCodeExportPlugin reason:anError];
}

/*
 
 open file with default application associated with its type
 
 */
- (BOOL)openFileWithDefaultApplication:(NSString *)fullPath
{
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	
	return [workspace openFile:fullPath];
}

/*
 
 complete path including extension
 
 */
- (NSString *)completePath:(NSString *)aPath
{
	// expand path
	NSString *path = [aPath stringByExpandingTildeInPath];
	
	// add extension if not present
	if (NSOrderedSame != [[path pathExtension] caseInsensitiveCompare:[self fileExtension]]) {
		path = [path stringByAppendingPathExtension:[self fileExtension]];
	}
	
	return path;
}

/*
 
 is display default
 
 */
- (BOOL)isDisplayDefault
{
	return NO;
}
@end
