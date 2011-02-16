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
	NSString *reverseURL;
}

+ (id)sharedController;
- (id) initWithReverseURL:(NSString *)URL;
- (NSString *)storageFileWithOptions:(NSDictionary *)options;
- (NSString *)storageDirectoryWithOptions:(NSDictionary *)options;
- (BOOL)removeStorageItemAtPath:(NSString *)path;
- (NSString *)storageDirectory;
- (NSString *)storagePath;
- (void)deleteStorageFacility;

@property (copy) NSString *reverseURL;

@end
