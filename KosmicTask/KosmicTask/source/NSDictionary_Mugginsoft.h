//
//  NSDictionary_Mugginsoft.h
//  Mother
//
//  Created by Jonathan on 03/07/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define MGSPreserveKeyCase 0
#define MGSLowerKeyCase 1
#define MGSUpperKeyCase 2

@interface NSDictionary (Mugginsoft)

- (id)objectForKey:(NSString *)key withDefault:(id)defValue;
- (NSString *)propertyListStringValue;
- (NSDictionary *)dictionaryWithObjectsAndKeysAsStrings;
- (NSString *)stringValueWithFormat:(NSString *)format;
- (id)mgs_objectForKeys:(NSArray *)searchKeys caseSensitive:(BOOL)caseInsensitive;
@end
