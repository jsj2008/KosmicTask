//
//  MGSScriptParameter.h
//  Mother
//
//  Created by Jonathan on 09/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSDictionary.h"

@interface MGSScriptParameter : MGSDictionary {
	BOOL _modelDataModified;
}
+ (id)new;
//- (NSString *)type_;
//- (void)setType_:(NSString *)aString;
- (id)value;
- (void)setValue:(id)object;
- (id)valueOrNil;
//- (void)setDefault:(NSString *)aString;
- (id)defaultValue;
- (id)mutableCopyWithZone:(NSZone *)zone;

// plugin type name
- (NSString *)typeName;
- (void)setTypeName:(NSString *)aString;

// plugin type info
- (NSMutableDictionary *)typeInfo;
- (void)resetTypeInfo;

// send as attachment
- (BOOL)sendAsAttachment;
- (void)setSendAsAttachment:(BOOL)value;

// attachment index
- (NSInteger)attachmentIndex;
- (void)setAttachmentIndex:(NSInteger)value;

@property BOOL modelDataModified;
@end
