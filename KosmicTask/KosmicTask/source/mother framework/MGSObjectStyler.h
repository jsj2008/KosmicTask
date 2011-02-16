//
//  MGSObjectStyler.h
//  KosmicTask
//
//  Created by Jonathan on 07/04/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *MGSLevelStyleName;

// style dictionary keys
extern NSString *MGSStyleFilter;
extern NSString *MGSStyleLevel;

// terminator styles
extern NSString *MGSTerminatorStyleName;
extern NSString *MGSAppendTerminatorStyleName;

// default styles
extern NSString *MGSDefaultAttributesStyleName;

// dict styles
extern NSString *MGSDictAttributesStyleName;
extern NSString *MGSDictKeySuffixStyleName;
extern NSString *MGSDictFilterStyleName;
extern NSString *MGSDictKeyAttributesStyleName;
extern NSString *MGSDictObjectAttributesStyleName;
extern NSString *MGSDictKeyFilterStyleName;
extern NSString *MGSDictInLineStyleName;

// string styles
extern NSString *MGSComputedAttributesStyleName;

// array styles
extern NSString *MGSArrayAttributeStyleName;
extern NSString *MGSArrayEvenAttributeStyleName;
extern NSString *MGSArrayOddAttributesStyleName;

extern NSString *MGSBackgroundColorAttributeStyleName;

@interface MGSObjectStyler : NSObject {
	id targetObject;
}

+ (NSMutableDictionary *)baseAttributes;
+ (NSDictionary *)styleDictionaryWithAttributes:(NSDictionary *)defaultDict;
+ (MGSObjectStyler *)stylerWithObject:(id)object;
- (MGSObjectStyler *)initWithObject:(id)object;
- (MGSObjectStyler *)init;
- (NSAttributedString *)descriptionWithStyle:(NSDictionary *)inputStyleDict;
- (NSAttributedString *)object:(id)object descriptionWithStyle:(NSDictionary *)inputStyleDict;
@end
