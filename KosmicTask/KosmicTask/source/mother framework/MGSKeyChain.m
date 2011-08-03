//
//  MGSKeyChain.m
//  Mother
//
//  Created by Jonathan on 31/03/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSKeyChain.h"
#import "EMKeyChain.h"
#import "EMKeychainItem_Mugginsoft.h"

NSString *MGSKeyPassword = @"password";
NSString *MGSKeyUsername = @"username";
NSString *MGSSession = @".{Session}";

@implementation MGSKeyChain

// session service name
+ (NSString *)sessionService:(NSString *)service
{
	return [service stringByAppendingString:MGSSession];
}

// add service to keychain
// service name will uniquely identify the item in combination with the user name.
// the label property controls the items displayed name in the keychain.
+ (EMGenericKeychainItem *)addService:(NSString *)service withUsername:(NSString *)username password:(NSString *)password
{
	NSString *chainService = [self chainServiceName:service];
	
	// check for existing item.
    // we only ever wnat to have one keychain entry for this service
    EMGenericKeychainItem *item  = [EMGenericKeychainItem genericKeychainItemForService:chainService];

	if (item) {
        [item setUsername:username];
		[item setPassword:password];
	} else {	
		// on occasion this call fails.
		// underlying error code is -67061, which does not seem recognisable.
		// see MID: 607.
		// one cause was an NSTextView getting sent -setString:nil
		// maybe a threading issue?
		item = [EMGenericKeychainItem addGenericKeychainItemForService:chainService withUsername:username password:password];
		[item setDescription: @"KosmicTask application password"];	// keychain displays as Kind
	}
	
	return item;
}

// Get password for service and user name.
+ (NSString *)passwordForService:(NSString *)service withUsername:(NSString *)username
{
  
	EMGenericKeychainItem *item  = [EMGenericKeychainItem 
									genericKeychainItemForService: [ self chainServiceName:service] 
									withUsername:username];

	return [item password];
}

// Get password and username for service 
// if there is more than one matching service entry this code returns the first match
+ (NSDictionary *)passwordAndUsernameForService:(NSString *)service 
{
	EMGenericKeychainItem *item  = [EMGenericKeychainItem
									genericKeychainItemForService: [self chainServiceName:service]];
	if (!item) return nil;
	
	return [NSDictionary dictionaryWithObjectsAndKeys: [item password], MGSKeyPassword, [item username], MGSKeyUsername, nil];
}

// chain service name
+ (NSString *)chainServiceName:(NSString *)service
{
	return [NSString stringWithFormat:@"KosmicTask: %@", service];
}

// delete service
+ (BOOL)deleteService:(NSString *)service withUsername:(NSString *)username
{
    EMGenericKeychainItem *item = [EMGenericKeychainItem 
                                   genericKeychainItemForService:[self chainServiceName:service] 
                                   withUsername:username];
    if (!item) return NO;
    
    // see API documentation for SecKeychainItemDelete
    /* 
     Do not delete a keychain item and recreate it in order to modify it; instead, use the SecKeychainItemModifyContent or SecKeychainItemModifyAttributesAndData function to modify an existing keychain item. When you delete a keychain item, you lose any access controls and trust settings added by the user or by other applications.
    */
    
    [item remove];
    
    return YES;
}

@end
