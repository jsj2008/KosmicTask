//
//  MGSL.m
//  Mother
//
//  Created by Jonathan on 29/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSL.h"
#import "MGSMother.h"
#import "MGSUser.h"
#import "MGSAPLicenceCode.h"

@interface MGSL (Private)
@end

@implementation MGSL

/*
 
 default licence type for user
 
 */
+ (NSNumber *)defaultType
{
    // on lion non admin users can no longer write to /library/application support
    // so better to disable support for it
	NSInteger licenceType = ([[MGSUser currentUser] isMemberOfAdminGroup] && NO) ? MGSLTypeComputer: MGSLTypeIndividual;
	return [NSNumber numberWithInteger:licenceType];
}
/*
 
 init with path
 
 */
- (id)initWithPath:(NSString *)path
{
	if ((self = [super init])) {
		_path = path;
	}
	return self;
}
/*
 
 init with data
 
 */
- (id)initWithData:(NSData *)data
{
	if ((self = [super init])) {
		_data = data;
	}
	return self;
}

/*
 
 init with plist
 
 */
- (id)initWithPlist:(id)plist
{
	NSString *error = nil;
	NSData *data = [NSPropertyListSerialization dataFromPropertyList:plist
												format:NSPropertyListXMLFormat_v1_0
												errorDescription:&error];
	if (!data || error) {
		NSLog(@"initWithPlist: failed: %@", *error);
		return nil;
	}
	return [self initWithData:data];
}

/*
 
 validate  

 */
- (BOOL)valid
{	
	return MGSAPVerifyLicense([self dataSource]);
}

/*
 
 data source
 
 */
- (id)dataSource
{
	id source = nil;
	
	if (_path) {
		source = _path;
	} else {
		source =_data;
	}
	
	return source;
}
/*
 
 get dictionary rep
 
 this dictionary is used for display purposes only not for validation
 */
- (NSDictionary *)dictionary
{
	// Get the dictionary from the license file
	// If the license is invalid, we get nil back instead of a dictionary
	if (!_dictionary) {
		_dictionary = MGSAPLicenceDictionary([self dataSource], [self optionDictPath], [[self class] defaultType]);
	}
	return _dictionary;
}

/*
 
 get licence plist rep
 
 */
- (id)plist
{
	NSData *data = [self data];
	NSPropertyListFormat plistFormat;
	NSString *error = nil;
	id plist = [NSPropertyListSerialization propertyListFromData:data 
									 mutabilityOption:NSPropertyListMutableContainersAndLeaves 
									format:&plistFormat errorDescription:&error];
	if (error) {
		NSLog(@"plist failed: %@", error);
	}
	return plist;
}
/*
 
 licence data
 
 */
- (NSData *)data
{
	// return data if available
	if (_data) {
		return _data;
	}
	
	// get data from path
	NSError *error = nil;
	NSData *fileData = [NSData dataWithContentsOfFile:_path options:0 error:&error];
	if (!fileData) {
		NSLog(@"dataWithContentsOfFile failed: %@", error);
	}
	return fileData;
}

/*
 
 Option dictionary path
 
 The option dictionary holds additional public info with regard to the licence.
 Such as when it was installed and the install mode.
 
 */
- (NSString *)optionDictPath
{
	if (!_path) {
		return nil;
	}
	
	NSString *optionDictPath = [_path stringByDeletingPathExtension];
	return [optionDictPath stringByAppendingPathExtension:@"plist"];
}
/* 
 
 is trial licence
 
 do not use this function to restrict functionality for trial verions.
 
 use MGSAPLicenceIsRestrictiveTrial() to test for restricted functionailty
 
 */
- (BOOL)isTrial
{
	return [[self dictionary] objectForKey:MGSTrialLicenceKey] ? YES : NO;
}

/*
 
 owner
 
 */
- (NSString *)owner
{
	return [[self dictionary] objectForKey:MGSOwnerLicenceKey];
}

/*
 
 type
 
 */
- (NSNumber *)type
{
	return [[self dictionary] objectForKey:MGSTypeLicenceKey];
}
/*
 
 seats
 
 */
- (NSString *)seats
{
	return [[self dictionary] objectForKey:MGSSeatsLicenceKey];
}


/*
 
 seat count
 
 */
- (NSUInteger)seatCount
{
	NSInteger count = 0;
	
	// scan count
	[[NSScanner scannerWithString:[self seats]] scanInteger:&count];
	
	return (NSUInteger)count;
}
/*
 
 hash
 
 */
- (NSString *)hash
{
	return [[self dictionary] objectForKey:MGSHashLicenceKey];
}

/*
 
 path
 
 */
- (NSString *)path
{
	return _path;
}
@end


@implementation MGSL (Private)

@end

