//
//  MGSAuthentication.h
//  Mother
//
//  Created by Jonathan on 22/03/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MGSNetClient;


extern const NSString *MGSAuthenticationKeyChallenge;
extern const NSString *MGSAuthenticationKeyAlgorithm;

extern const NSString *MGSAuthenticationKeyUsername;
extern const NSString *MGSAuthenticationKeyResponse;
extern const NSString *MGSAuthenticationKeyPassword;

// algorithms
extern const NSString *MGSAuthenticationCRAM_MD5;
extern const NSString *MGSAuthenticationClearText;

@interface MGSAuthentication : NSObject {

}

+ (id)sharedController;
+ (NSString *)localHost;

- (BOOL)authenticateWithDictionary:(NSDictionary *)authDict;
- (NSDictionary *)authenticationChallenge:(NSString *)algorithm;
- (BOOL)authenticateCRAMMD5ForUsername:(NSString *)username challenge:(NSString *)challenge response:(NSString *)response;
- (BOOL)authenticateClearTextForUsername:(NSString *)username password:(NSString *)password;
- (NSDictionary *)responseToChallenge:(NSDictionary *)challengeDict password:(NSString *)password username:(NSString *)username;
- (NSString *)CRAM_MD5Challenge;
- (NSDictionary *)responseDictionaryforSessionService:(NSString *)service password:(NSString *)password username:(NSString *)username;
- (NSDictionary *)authDictionaryforService:(NSString *)service withDictionary:(NSDictionary *)authDict;
- (BOOL)deleteKeychainPasswordForService:(NSString *)service withDictionary:(NSDictionary *)authDict;
- (BOOL)deleteKeychainSessionPasswordForService:(NSString *)service withDictionary:(NSDictionary *)authDict;
- (BOOL)createKeychainSessionPasswordForService:(NSString *)service password:(NSString *)password username:(NSString *)username;
- (BOOL)createKeychainPasswordForService:(NSString *)service password:(NSString *)password username:(NSString *)username;
- (BOOL)createKeychainDefaultSessionPasswordForService:(NSString *)service username:(NSString *)username;
- (NSDictionary *)authDictionaryforSessionService:(NSString *)service withDictionary:(NSDictionary *)authDict;
- (void)credentialsForService:(NSString *)service password:(NSString **)outPassword username:(NSString **)inoutUsername;
- (void)credentialsForSessionService:(NSString *)service password:(NSString **)outPassword username:(NSString **)inoutUsername;
- (BOOL)deleteKeychainSessionPasswordForService:(NSString *)service;
- (BOOL)authenticateLocalHostWithDictionary:(NSDictionary *)authDict;
@end
