//
//  MGSScriptGroup.h
//  Mother
//
//  Created by Jonathan on 16/11/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MGSScriptGroup : NSObject {
	NSMutableDictionary *_groupDictionary;
}

- (id)initWithContentsOfFile:(NSString *)path;
- (NSMutableArray *)groupResourceIcons;
- (NSImage *)imageForGroupName:(NSString *)name;
- (NSImage *)imageForGroup;
- (NSImage *)imageForAllGroup;
- (NSImage *)imageForName:(NSString *)name location:(NSString *)location;
- (NSImage *)defaultImageForAllGroup;
- (NSImage *)defaultImageForGroup;
- (void)setImageResourceForGroupName:(NSString *)groupName imageName:(NSString *)imageName location:(NSString *)location;
- (void)setImageResourceForAllGroup:(NSString *)imageName location:(NSString *)location;
- (BOOL)saveToPath:(NSString *)path;

- (void)imageResourceForGroupName:(NSString *)groupName imageName:(NSString **)imageName location:(NSString **)location;
- (void)imageResourceForAllGroup:(NSString **)imageName location:(NSString **)location;
- (void)imageResourceForGroup:(NSString **)imageName location:(NSString **)location;
@end
