//
//  MGSSystem.m
//  Mother
//
//  Created by Jonathan on 29/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSSystem.h"
#import "NSApplication_Mugginsoft.h"

#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
#include <SystemConfiguration/SCDynamicStoreCopySpecific.h>

// minimum required OS for app
#define MOTHER_MIN_OS_MAJOR 10
#define MOTHER_MIN_OS_MINOR 6
#define MOTHER_MIN_OS_BUGFIX 0

void CopySerialNumber(CFStringRef *serialNumber);

static MGSSystem *_sharedInstance = nil;
static NSString *sharedInstanceSemaphore = @"sharedInstanceSemaphore";

@implementation MGSSystem

/* 
 
 shared instance
 
 */
+ (id)sharedInstance
{
	@synchronized (sharedInstanceSemaphore) {

		if (nil == _sharedInstance) {
			_sharedInstance = [[self alloc] init];
		}
	}
	
	return _sharedInstance;
} 


/*
 
 validate that OS version is supported
 
 */
- (BOOL)OSVersionIsSupported
{
	unsigned major, minor, bugFix;
	
	[NSApplication getSystemVersionMajor:&major minor:&minor bugFix:&bugFix];
	// bugFix >= MOTHER_MIN_OS_BUGFIX generates pedantic warning when MOTHER_MIN_OS_BUGFIX == 0
	return (minor > MOTHER_MIN_OS_MINOR || 			
			(major == MOTHER_MIN_OS_MAJOR && minor == MOTHER_MIN_OS_MINOR && 
			 (bugFix == MOTHER_MIN_OS_BUGFIX || bugFix > MOTHER_MIN_OS_BUGFIX))) ? YES : NO;

}

/*
 
 min OS version supported
 
 */
- (NSString *)minOSVersionSupported
{
	return [NSString stringWithFormat:@"%i.%i.%i", MOTHER_MIN_OS_MAJOR, MOTHER_MIN_OS_MINOR, MOTHER_MIN_OS_BUGFIX];
}

/*
 
 machine serial number
 
 see http://developer.apple.com/technotes/tn/tn1103.html
 
 */
- (NSString *)machineSerialNumber
{
	NSString *serial = @"unknown";
	
	CFStringRef serialNumber;
	CopySerialNumber(&serialNumber);
	
	if (serialNumber != NULL) {
		serial = [(NSString *)serialNumber copy];
		CFRelease(serialNumber);
	}
	
	return serial;

}

/*
 
 localhost name
 
 */
- (NSString *)localHostName
{
	// was using [[NSHost currentHost] name] and [[NSProcessInfo processInfo] hostName]
	// on 10.5 without too much trouble but on 10.6 they block very badly.
	// even on 10.5 they may be slow because launch times seem much improved now.
	
	// this omits the .local pseudo domain but seems more modern
	NSString *name = nil;
	if (1) {
		name = NSMakeCollectable(SCDynamicStoreCopyLocalHostName(NULL));
		name = [name stringByAppendingString:@".local"];
	} else {
		// or gethostname
		char hostname[_POSIX_HOST_NAME_MAX + 1];
		gethostname(hostname, _POSIX_HOST_NAME_MAX);
		name = [NSString stringWithCString:hostname encoding:NSUTF8StringEncoding];
	}
	
	return name;
}
@end


// Returns the serial number as a CFString.
// It is the caller's responsibility to release the returned CFString when done with it.
void CopySerialNumber(CFStringRef *serialNumber)
{

	if (serialNumber != NULL) {
		*serialNumber = NULL;
		
		io_service_t    platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault,
																	 IOServiceMatching("IOPlatformExpertDevice"));
		
		if (platformExpert) {
			CFTypeRef serialNumberAsCFString =
			IORegistryEntryCreateCFProperty(platformExpert,
											CFSTR(kIOPlatformSerialNumberKey),
											kCFAllocatorDefault, 0);
			if (serialNumberAsCFString) {
				*serialNumber = serialNumberAsCFString;
			}
			
			IOObjectRelease(platformExpert);
		}
	}
}
