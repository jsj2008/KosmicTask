//
//  MGSKeyChain.h
//  Mother
//
//  Created by Jonathan on 31/03/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *MGSKeyPassword;
extern NSString *MGSKeyUsername;

@class EMGenericKeychainItem;

@interface MGSKeyChain : NSObject {
}
+ (NSString *)sessionService:(NSString *)service;
+ (EMGenericKeychainItem *)addService:(NSString *)service withUsername:(NSString *)username password:(NSString *)passwordString;
+ (NSString *)chainServiceName:(NSString *)service;
+ (NSString *)passwordForService:(NSString *)service withUsername:(NSString *)username;
+ (NSDictionary *)passwordAndUsernameForService:(NSString *)service;
+ (BOOL)deleteService:(NSString *)service withUsername:(NSString *)username;
@end
