//
//  EMKeychainProxy_Mugginsoft.m
//  Mother
//
//  Created by Jonathan on 22/04/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
#import "EMKeychainProxy.h"
#import "EMKeychainProxy_Mugginsoft.h"

@implementation EMKeychainProxy (Mugginsoft)

// generic keychain item for service
// returns first item matching the service criteria.
- (EMGenericKeychainItem *)genericKeychainItemForService:(NSString *)serviceNameString
{
	const char *serviceName = [serviceNameString UTF8String];
	
	UInt32 passwordLength = 0;
	char *password = nil;
	
	SecKeychainItemRef item = nil;
	OSStatus returnStatus = SecKeychainFindGenericPassword(NULL, strlen(serviceName), serviceName, 0, NULL, &passwordLength, (void **)&password, &item);
	if (returnStatus != noErr || !item)
	{
		if (_logErrors)
		{
			NSLog(@"Error (%@) - %s", NSStringFromSelector(_cmd), GetMacOSStatusErrorString(returnStatus));
		}
		return nil;
	}
	NSString *passwordString = [NSString stringWithCString:password length:passwordLength];
	SecKeychainItemFreeContent(NULL, password);	// free the password data
	
	// search sec item for account name
	SecKeychainAttribute attributes[2];
	SecKeychainAttributeList list;
	attributes[0].tag = kSecAccountItemAttr;
	list.count = 1;
	list.attr = attributes;
	
	returnStatus = SecKeychainItemCopyContent(item, NULL, &list, NULL, NULL);
	if (returnStatus != noErr)
	{
		if (_logErrors)
		{
			NSLog(@"Error (%@) - %s", NSStringFromSelector(_cmd), GetMacOSStatusErrorString(returnStatus));
		}
		return nil;
	}
	
	// get the attribute data
	SecKeychainAttribute attr;
	attr = list.attr[0];
	char buffer[1024];
	strncpy(buffer, attr.data, attr.length);
	buffer[attr.length] = '\0';
	
	// get the username
	NSString *usernameString = [NSString stringWithCString:buffer length:attr.length];
	 
	SecKeychainItemFreeContent(&list, NULL);	// free the list
	
	return [EMGenericKeychainItem genericKeychainItem:item forServiceName:serviceNameString username:usernameString password:passwordString];
}

@end
