//
//  MGSTempStorage.h
//  KosmicTask
//
//  Created by Jonathan on 03/08/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *MGSTempFileTemporaryDirectory;
extern NSString *MGSTempFileSuffix;
extern NSString *MGSTempFileTemplate;
extern NSString *MGSKosmicTempFileNamePrefix;

@interface MGSTempStorage : NSObject {
	NSString *tempDirectory;
	NSString *storageFolder;
	BOOL alwaysGenerateUniqueFilenames;
}

+ (id)sharedController;
+ (NSString *)defaultReverseURL;
- (id) initWithFolder:(NSString *)URL;
- (id)initStorageFacility;
- (NSString *)storageFileWithOptions:(NSDictionary *)options;
- (NSString *)storageDirectoryWithOptions:(NSDictionary *)options;
- (BOOL)removeStorageItemAtPath:(NSString *)path;
- (NSString *)storageFacility;
- (NSString *)storagePath;
- (void)deleteStorageFacility;

@property (copy, nonatomic) NSString *storageFolder;
@property BOOL alwaysGenerateUniqueFilenames;

@end
