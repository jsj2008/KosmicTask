//
//  NSString_Mugginsoft.h
//  Mother
//
//  Created by Jonathan on 29/02/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSString (Mugginsoft)

+ (NSString *)mgs_stringWithNewUUID;
+ (NSString *)mgs_stringWithCreatedTempFilePath;
+ (NSString *)mgs_stringWithCreatedTempFilePathSuffix:(NSString *)suffix;
+ (NSString *)mgs_stringFromFileSize:(unsigned long long)theSize;
- (NSString *)mgs_stringWithOccurrencesOfCrLfRemoved;
- (NSString *)mgs_stringTerminatedWithPeriod;
- (NSString*)mgs_camelCaseString;
- (NSUInteger)mgs_occurrencesOfString:(NSString *)aString;
- (BOOL)mgs_isTempFilePathContaining:(NSString *)subString;
- (BOOL)mgs_isUUID;
- (NSString *)mgs_StringByReplacingCharactersInSet:(NSCharacterSet *) set withString:(NSString *) string;
- (NSString *)mgs_stringByRemovingNewLinesAndTabs;
- (BOOL)mgs_isURL;
- (BOOL)mgs_isURLorIPAddress;
+ (NSString *)mgs_StringWithSockAddrData:(NSData *)addressData;
- (BOOL)mgs_isIPAddress;
@end

@interface NSMutableString (Mugginsoft)
- (void)mgs_ReplaceCharactersInSet:(NSCharacterSet *) set withString:(NSString *) string;
@end


