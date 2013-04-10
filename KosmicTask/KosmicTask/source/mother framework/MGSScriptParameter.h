//
//  MGSScriptParameter.h
//  Mother
//
//  Created by Jonathan on 09/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSDictionary.h"


enum _MGSScriptParameterRepresentation {
	MGSScriptParameterRepresentationUndefined = 0,		// undefined representation
	MGSScriptParameterRepresentationStandard = 1,		// standard representation
	MGSScriptParameterRepresentationExecute = 2,			// execute representation 
};
typedef NSInteger MGSScriptParameterRepresentation;

enum {
    MGSScriptParameterVariableStatusNew = 0,
    MGSScriptParameterVariableStatusUsed = 1,
};
typedef NSInteger MGSScriptParameterVariableStatus;

enum {
    MGSScriptParameterVariableNameUpdatingAuto = 0,
    MGSScriptParameterVariableNameUpdatingManual = 1,
};
typedef NSInteger MGSScriptParameterVariableNameUpdating;

@interface MGSScriptParameter : MGSDictionary {
	BOOL _modelDataModified;    // not persisted
    NSUInteger _index;          // not persisted
    NSString *_typeDescription;
}
+ (NSString *)defaultDescription;
+ (id)new;
- (id)value;
- (void)setValue:(id)object;
- (id)valueOrNil;
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

// UUID
- (NSString *)UUID;
- (void)setUUID:(NSString *)value;

// variable name
- (NSString *)variableName;
- (void)setVariableName:(NSString *)value;

// variable status
- (MGSScriptParameterVariableStatus)variableStatus;
- (void)setVariableStatus:(MGSScriptParameterVariableStatus)value;

// variable name updating
- (MGSScriptParameterVariableNameUpdating)variableNameUpdating;
- (void)setVariableNameUpdating:(MGSScriptParameterVariableNameUpdating)value;

- (void)setRepresentation:(MGSScriptParameterRepresentation)value;
- (MGSScriptParameterRepresentation)representation;
- (BOOL)conformToRepresentation:(MGSScriptParameterRepresentation)representation;
- (BOOL)conformToRepresentation:(MGSScriptParameterRepresentation)representation options:(NSDictionary *)options;
- (void)removeRepresentation;
- (void)updateFromScriptParameter:(MGSScriptParameter *)scriptParameter options:(NSDictionary *)options;

@property BOOL modelDataModified;
@property NSUInteger index;
@property (copy) NSString *typeDescription;

@end
