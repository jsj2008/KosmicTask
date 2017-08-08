//
//  MGSLM.h
//  Mother
//
//  Created by Jonathan on 29/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *MGSNoteLicenceStatusChanged;

@class MGSL;

enum _MGSLMMode {
	MGSInvalidLicenceMode = 34,
	MGSValidLicenceMode = 1872
};
typedef NSInteger MGSLMMode;

@interface MGSLM : NSArrayController {
	NSString *__strong _lastError;
	MGSLMMode _mode;
}

@property (strong) NSString *lastError;
@property (readonly) MGSLMMode mode;

+ (void)buyLicences;
+ (void) initializePaths;
+ (NSMutableDictionary *)defaultOptionDictionary;
+ (id)sharedController;
- (BOOL)loadAll;
- (NSString *)extension;
- (NSString *)firstOwner;
- (BOOL)addItemAtPath:(NSString *)path withDictionary:(NSDictionary *)dictionary;
- (void)showLastError;
- (void)showSuccess;
- (NSString *)savePathFromLicenceType:(NSInteger)licenceType;
- (BOOL) validateItemAtPath:(NSString *)path;
- (NSDictionary *)dictionaryOfItemAtPath:(NSString *)path;
+ (NSString *)userApplicationSavePath;
- (BOOL)removeObjectAndFile:(MGSL *)licence;
- (NSArray *)allAppData;
- (NSUInteger)seatCount;
@end
