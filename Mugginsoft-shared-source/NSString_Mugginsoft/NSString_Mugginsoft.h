//
//  NSString_Mugginsoft.h
//  Mother
//
//  Created by Jonathan on 29/02/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSString (Mugginsoft)

+ (NSString *)stringWithNewUUID;
+ (NSString *)stringWithCreatedTempFilePath;
+ (NSString *)stringWithCreatedTempFilePathSuffix:(NSString *)suffix;
+ (NSString *)stringFromFileSize:(unsigned long long)theSize;
- (NSString *)stringWithOccurrencesOfCrLfRemoved;
- (NSString *)stringTerminatedWithPeriod;
- (NSString*)camelCaseString;

- (BOOL)isTempFilePathContaining:(NSString *)subString;
- (BOOL)isUUID;

@end
