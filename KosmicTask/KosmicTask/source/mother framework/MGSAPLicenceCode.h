/*
 *  MGSAPLicenceCode.h
 *  KosmicTask
 *
 *  Created by Jonathan on 02/12/2009.
 *  Copyright 2009 mugginsoft.com. All rights reserved.
 *
 */
#import "AquaticPrime.h"
#import "MGSAPLicence.h"
#import "mlog.h"

#define TRIAL_RESTRICTS_FUNCTIONALITY NO

/*
 AquaticPrime Licence Code validation
 
 including this header causes the static code to be embedded into the module
 
 */
static NSString *MGSAPPublicLicenceKey();
static NSDictionary *MGSAPLicenceDictionary(id dataSource, NSString *optionDictPath, NSNumber *defaultLicenceType);
static BOOL MGSAPSetKey();
static BOOL MGSAPVerifyLicenseFile(NSString *path) __attribute__((__unused__));
static BOOL MGSAPLicenceIsRestrictiveTrial() __attribute__((__unused__));
static id MGSAPLicenceDictionaryValue(NSString *key);
static BOOL MGSAPVerifyLicenseData(NSData *data);
static BOOL MGSAPVerifyLicense(id dataSource) __attribute__ ((unused)) ;

/*
 
 AquaticPrime public licence key
 
 */
static NSString *MGSAPPublicLicenceKey() {
	NSMutableString *key = [NSMutableString string];
	[key appendString:@"0x"];
	[key appendString:@"E"];
	[key appendString:@"E"];
	[key appendString:@"B979021E1655372F62B9DC24A9"];
	[key appendString:@"28D6E290"];
	[key appendString:@"B"];
	[key appendString:@"B"];
	[key appendString:@"381A976903A1EE165F4A"];
	[key appendString:@"EBE17"];
	[key appendString:@"F"];
	[key appendString:@"F"];
	[key appendString:@"0D1B9D6A61DF0DBB82F1DD6"];
	[key appendString:@"878B4BDCB"];
	[key appendString:@"A"];
	[key appendString:@"A"];
	[key appendString:@"48CEB78F16701C43CC1"];
	[key appendString:@"C"];
	[key appendString:@"3"];
	[key appendString:@"3"];
	[key appendString:@"4E9A04BC88641AD5FE8A42631A4"];
	[key appendString:@"CD"];
	[key appendString:@"8"];
	[key appendString:@"8"];
	[key appendString:@"AE2701679CACA9C735B9681652"];
	[key appendString:@"10252CFDA7D"];
	[key appendString:@"3"];
	[key appendString:@"3"];
	[key appendString:@"6A3B77325BE3636F6"];
	[key appendString:@"D146F4091EF2EF2B08F8C451ED0"];
	[key appendString:@"A"];
	[key appendString:@"A"];
	[key appendString:@"8"];
	[key appendString:@"C800C6042AA23FF2F5"];
	
	return [NSString stringWithFormat:@"%@", key];
}

/*
 
 set the key
 
 */
static BOOL MGSAPSetKey() {
	return APSetKey((CFStringRef)MGSAPPublicLicenceKey());
}

/*
 
 verify the licence
 
 */
static BOOL MGSAPVerifyLicense(id dataSource)
{	
	if ([dataSource isKindOfClass:[NSData class]]) {
		return MGSAPVerifyLicenseData(dataSource);
	} else if ([dataSource isKindOfClass:[NSString class]]) {
		return MGSAPVerifyLicenseFile(dataSource);
	}
	
	return NO;
}


/*
 
 verify the licence file
 
 */
static BOOL MGSAPVerifyLicenseFile(NSString *path)
{	
	if (!path) return NO;
	if (!MGSAPSetKey()) return NO;
	return APVerifyLicenseFile((CFURLRef)[NSURL fileURLWithPath:path]);
}
/*
 
 verify the licence data
 
 */
static BOOL MGSAPVerifyLicenseData(NSData *data)
{	
	if (!data) return NO;
	if (!MGSAPSetKey()) return NO;
	return APVerifyLicenseData((CFDataRef)data);
}
/*
 
 AquaticPrime licence dictionary
 
 */
static NSDictionary *MGSAPLicenceDictionary(id dataSource, NSString *optionDictPath, NSNumber *defaultLicenceType) {
	
	if (!MGSAPSetKey()) return nil;
	
	NSDictionary *_dictionary = nil;
	
	// create dictionary for licence data
	if ([dataSource isKindOfClass:[NSData class]]) {
		_dictionary = (NSDictionary *)APCreateDictionaryForLicenseData((CFDataRef)dataSource);
	}
	
	// create dictionary for licence file
	else if ([dataSource isKindOfClass:[NSString class]]) {
		_dictionary = (NSDictionary *)APCreateDictionaryForLicenseFile((CFURLRef)[NSURL fileURLWithPath:dataSource]);
	} else {
		return nil;
	}
	
	// add hash to dictionary
	NSMutableDictionary *mutableDict = [NSMutableDictionary dictionaryWithDictionary:_dictionary];
	[mutableDict setObject:(NSString *)APHash() forKey:MGSHashLicenceKey];
	
	// get option dictionary
	NSDictionary *optionDict = nil;
	if (optionDictPath) {
		optionDict = [NSDictionary dictionaryWithContentsOfFile:optionDictPath]; 
		
		// do I really want to log this?
		if (!optionDict && NO) {
			MLog(DEBUGLOG, @"Licence option file missing");
		}
	}
	
	// add option dict contents to our licence dictionary
	
	// date licence added
	NSString *dateAdded = [optionDict objectForKey:MGSAddedLicenceKey];
	if (!dateAdded) {
		dateAdded = @"Unknown";
	}
	[mutableDict setObject:dateAdded forKey:MGSAddedLicenceKey];
	
	// licence type
	NSNumber *licenceType = [optionDict objectForKey:MGSTypeLicenceKey];
	if (!licenceType) {
		// supply default if missing
		licenceType = defaultLicenceType;
	}
	[mutableDict setObject:licenceType forKey:MGSTypeLicenceKey];
	
	// availability is derived from licence type
	NSString *availability = nil;
	switch ([licenceType intValue]) {
		case MGSLTypeComputer:
			availability = @"All users of this computer";
			break;
			
		case MGSLTypeIndividual:
		default:
			availability = @"Current user only";
			break;
	}
	[mutableDict setObject:availability forKey:MGSAvailabilityLicenceKey];
	
	// return this
	_dictionary = [NSDictionary dictionaryWithDictionary:mutableDict];
	
	return _dictionary;
	
}

/*
 
 licence is trial
 
 use this function to restrict functionality for trial verions
 
 */
static BOOL MGSAPLicenceIsRestrictiveTrial() 
{

	// if this is an expiring build then do not restrict
	// functionality
#if EXPIREAFTERDAYS
	return NO;
#endif
	
	id value = MGSAPLicenceDictionaryValue(MGSTrialLicenceKey);
	return value ? YES : NO;
}

/*

 licence dictionary value
 
*/
static id MGSAPLicenceDictionaryValue(NSString *key) {
	
	NSArray *licences = [[MGSLM sharedController] arrangedObjects];
	if (!licences || ![licences lastObject]) {
		abort();
	}
	
	// search all licences for value
	for (MGSL *licence in licences) {
		NSDictionary *licenceDict = MGSAPLicenceDictionary([licence path], nil, [NSNumber numberWithInteger:MGSLTypeIndividual]);
		id item  = [licenceDict objectForKey:key];
		if (item) return item;
	}
	
	return nil;	
}

