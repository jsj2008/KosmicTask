//
//  MGSDictionary.h
//  Mother
//
//  Created by Jonathan on 08/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSDictionary_Localize.h"
#import "NSMutableDictionary_Localize.h"

@interface MGSDictionary : NSObject <NSMutableCopying> {
	NSMutableDictionary *_dict;
	NSString *_preferredLang;
}
+ (id) newDict;
+ (id) dictWithDict:(NSMutableDictionary *)dict;
- (id)initWithDictionary:(NSDictionary *)dict;
- (void)setDict:(NSMutableDictionary *)dict;
- (NSMutableDictionary *)dict;
- (NSString *)name;
- (void)setName:(NSString *)aString;
- (NSString *)description;
- (void)setDescription:(NSString *)aString;
- (id)objectForLocalizedKey:(NSString *)key;
- (void)setObject:(id)obj forLocalizedKey:(NSString *)key;
- (id) mutableCopyWithZone:(NSZone *)zone;
- (id)mutableDeepCopy;
- (void)copyDictFrom:(MGSDictionary *)aDict;
- (NSMutableDictionary *)dictMutableDeepCopy;
- (void)setObject:(id)obj forKey:(NSString *)key;
- (void)setBool:(BOOL)value forKey:(NSString *)key;
- (BOOL)boolForKey:(NSString *)key;
- (id)objectForKey:(NSString *)key;
- (void)removeObjectForKey:(NSString *)key;
- (void) setObject:(id)object forKey:(NSString *)key appending:(NSString *)language;
- (void) removeObjectForKey:(NSString *)key appending:(NSString *)language;
- (NSInteger)integerForKey:(NSString *)key;
- (void)setInteger:(NSInteger)value forKey:(NSString *)key;

- (BOOL)saveToPath:(NSString *)path;
- (NSData *)propertyListData;

- (void)assignObject:(id)obj forKey:(NSString *)key;
- (BOOL)syncWithDict:(NSDictionary *)syncDict;

- (id)objectForKey:(NSString *)key appending:(NSString *)language;
- (NSString *)localizeKey:(NSString *)key appending:(NSString *)language;
@end
