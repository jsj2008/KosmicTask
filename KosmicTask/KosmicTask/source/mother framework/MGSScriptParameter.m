//
//  MGSScriptParameter.m
//  Mother
//
//  Created by Jonathan on 09/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSMother.h"
#import "MGSScriptParameter.h"
#import "MGSScriptPlist.h"
#import "NSString_Mugginsoft.h"

@interface MGSScriptParameter()
@end

@implementation MGSScriptParameter


@synthesize modelDataModified = _modelDataModified;
@synthesize index = _index;
@synthesize typeDescription = _typeDescription;

+ (NSString *)defaultDescription
{
	return NSLocalizedString(@"Enter input.", @"New parameter description");
}

/*
 
 create a new parameter
 
 */
+ (id)new
{
    return [self newWithTypeName:nil];
}

+ (id)newWithTypeName:(NSString *)pluginClassName
{
	MGSScriptParameter *parameter = [self newDict];
	
	[parameter setName:NSLocalizedString(@"Task Input", @"New input parameter name")];
	[parameter setDescription:[self defaultDescription]];
	[parameter setUUID:[NSString mgs_stringWithNewUUID]];
    [parameter setVariableStatus:MGSScriptParameterVariableStatusNew];
    [parameter setVariableNameUpdating:MGSScriptParameterVariableNameUpdatingAuto];

	// set plugin class name
	[parameter setTypeName:pluginClassName];
	
	// create class info mutable dict
	// note that we use assign rather than set.
	// set will create a copy of our object by default.
	// and that copy will be immutable.
	[parameter assignObject:[NSMutableDictionary dictionaryWithCapacity:2] forKey:MGSScriptKeyClassInfo];
	
	[parameter setRepresentation:MGSScriptParameterRepresentationStandard];

	return parameter;
}

/*
 
 init
 
 */
- (id)init
{
	self = [super init];
	if (self) {
		_modelDataModified = NO;
	}
	return self;
}

// this will be called by the binding machinery to
// modify the model data
- (void)setValue:(id)value forKeyPath:(NSString *)keyPath
{
	[super setValue:value forKeyPath:keyPath];
	self.modelDataModified = YES;
}

/*
 
 type name
 
 cannot use className as method name as it would act as an override
 
 */
- (NSString *)typeName
{
	return [self objectForKey:MGSScriptKeyClassName];
}
/* 
 
 set type name
 
 */
- (void)setTypeName:(NSString *)aString
{
	[self setObject:aString forKey:MGSScriptKeyClassName];
}


/*
 
 send as attachment
 
 */
- (BOOL)sendAsAttachment
{
	return [self boolForKey:MGSScriptKeySendAsAttachment];
}

/* 
 
 set send as attachment
 
 */
- (void)setSendAsAttachment:(BOOL)value
{
	[self setBool:value forKey:MGSScriptKeySendAsAttachment];
}

/*
 
 attachment index
 
 */
- (NSInteger)attachmentIndex
{
	return [self integerForKey:MGSScriptKeyAttachmentIndex];
}

/* 
 
 set attachment index
 
 */
- (void)setAttachmentIndex:(NSInteger)value
{
	[self setInteger:value forKey:MGSScriptKeyAttachmentIndex];
}

/*
 
 type info
 
 we do not provide a setter here as our overridden default implementation of 
 -setObject:forKey: automatically copies the object and currently
  a copied NSMutableDictionary is an instance of NSDictionary
 
 */
- (NSMutableDictionary *)typeInfo
{
	return [self objectForKey:MGSScriptKeyClassInfo];
}

/*
 
 reset the type info
 
 */
- (void)resetTypeInfo
{
	NSMutableDictionary *info = [self typeInfo];
	[info removeAllObjects];
}
/*
 
 default value
 
 */
- (id)defaultValue
{
	return [[self typeInfo] objectForKey:MGSScriptKeyDefault];
}
/*
 
 value
 
 if no value set then the default is returned
 
 */
- (id)value
{
	id value = [self objectForKey:MGSScriptKeyValue];
	if (value) {
		return value;
	}
	
	// if no value use default
	return [self defaultValue];
}
/*
 
 value
 
 if no value set then nil is returned
 
 */
- (id)valueOrNil
{
	return [self objectForKey:MGSScriptKeyValue];
}
/*
 
 - setValue:
 
 */
- (void)setValue:(id)object
{
	[self setObject:object forKey:MGSScriptKeyValue];
}

/*
  
 - UUID
 
 */
- (NSString *)UUID
{
	return [self objectForKey:MGSScriptKeyUUID];
}
/*
 
 - setUUID:
 
 */
- (void)setUUID:(NSString *)value
{
	[self setObject:value forKey:MGSScriptKeyUUID];
}

/*
 
 - variableName
 
 */
- (NSString *)variableName
{
    return [self objectForKey:MGSScriptKeyVariableName];
}

/*
 
 - setVariableName
 
 */
- (void)setVariableName:(NSString *)value
{
    [self setObject:value forKey:MGSScriptKeyVariableName];
}
/*
 
 - validateVariableName:error:
 
 */
-(BOOL)validateVariableName:(id *)ioValue error:(NSError **)outError
{
    NSString *errorString = nil;
    NSString *value = (NSString *)*ioValue;
    
    // disallow empty string
    if (!value || [value length] == 0) {
        errorString = NSLocalizedString(@"Variable name is empty", @"validation: VariableName, empty");
    } else {
    
        // languages may have complex variable validation.
        // we keep it simple here
        NSRange range = [value rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]];
        if (range.location != NSNotFound) {
            errorString = NSLocalizedString(@"Variable name contains invalid character", @"validation: VariableName, invalid");
        }
    }
    
    // deal with error
    if (errorString) {
        if (outError != NULL) {
            NSDictionary *userInfoDict = @{ NSLocalizedDescriptionKey : errorString };
            *outError = [[NSError alloc] initWithDomain:MGSErrorDomainMotherFramework
                                               code:0
                                           userInfo:userInfoDict];
        }
        return NO;
    }

    return YES;
}

/*
 
 - variableStatus
 
 */
- (MGSScriptParameterVariableStatus)variableStatus
{
    return [self integerForKey:MGSScriptKeyVariableStatus];
}

/*
 
 - setVariableStatus
 
 */
- (void)setVariableStatus:(MGSScriptParameterVariableStatus)value
{
    [self setInteger:value forKey:MGSScriptKeyVariableStatus];
}

/*
 
 - variableNameUpdating
 
 */
- (MGSScriptParameterVariableNameUpdating)variableNameUpdating
{
    return [self integerForKey:MGSScriptKeyVariableNameUpdating];
}

/*
 
 - setVariableNameUpdating:
 
 */
- (void)setVariableNameUpdating:(MGSScriptParameterVariableNameUpdating)value
{
    [self setInteger:value forKey:MGSScriptKeyVariableNameUpdating];
}

#pragma mark -
#pragma mark Updating
/*
 
 - updateFromScript:options:
 
 */
- (void)updateFromScriptParameter:(MGSScriptParameter *)scriptParameter options:(NSDictionary *)options
{

    NSArray * updates = [options objectForKey:@"updates"];

    // find and apply updates
    if (updates && [updates isKindOfClass:[NSArray class]]) {
        
        // all parameter variables
        if ([updates containsObject:@"allScriptParameterVariables"]) {
            self.variableName = scriptParameter.variableName;
            self.variableNameUpdating = scriptParameter.variableNameUpdating;
            self.variableStatus = scriptParameter.variableStatus;
        }
    }
}

#pragma mark -
#pragma mark Copying
/*
 
 mutable copy with zone
 
 */
- (id)mutableCopyWithZone:(NSZone *)zone
{
	MGSScriptParameter *aCopy = [super mutableCopyWithZone:zone];
    
	return aCopy;
}

/*
 
 mutable deep copy
 
 */
- (id)mutableDeepCopy
{
	MGSScriptParameter *aCopy = [super mutableDeepCopy];
    
	return aCopy;
}

#pragma mark -
#pragma mark Representation

/*
 
 - removeRepresentation
 
 */
- (void)removeRepresentation
{
	[self setObject:nil forKey:MGSScriptKeyRepresentation];
}

/*
 
 - setRepresentation:
 
 */
- (void)setRepresentation:(MGSScriptParameterRepresentation)value
{
	switch (value) {
		case MGSScriptParameterRepresentationUndefined:
		case MGSScriptParameterRepresentationStandard:
		case MGSScriptParameterRepresentationExecute:
			break;
			
		default:
			NSAssert(NO, @"invalid script representation");
	}
	
	[self setInteger:value forKey:MGSScriptKeyRepresentation];
}

/*
 
 - representation
 
 */
- (MGSScriptParameterRepresentation)representation
{
	return [self integerForKey:MGSScriptKeyRepresentation];
}

/*
 
 - conformToRepresentation:
 
 */
- (BOOL)conformToRepresentation:(MGSScriptParameterRepresentation)representation
{
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
							 [NSNumber numberWithBool:YES], @"conform",
							 nil];
	
	return [self conformToRepresentation:representation options:options];
}

/*
 
 - conformToRepresentation:options:
 
 */
- (BOOL)conformToRepresentation:(MGSScriptParameterRepresentation)representation options:(NSDictionary *)options
{
	BOOL success = YES;
	BOOL conform = [[options objectForKey:@"conform"] boolValue];
	
	if ([self representation] == representation) {
		return YES;
	}
	
	// we can only conform to a representation that contains fewer
	// dictionary keys then we have presently
	switch ([self representation]) {
			
			// standard representation
		case MGSScriptParameterRepresentationStandard:
			
			switch (representation) {
										
					/*
					 
					 build an execute representation.
					 
					 */
				case MGSScriptParameterRepresentationExecute:
					if (conform) {
						[self setTypeName:nil];
						[self setDescription:nil];
						[self setObject:nil forKey:MGSScriptKeyClassInfo];
					}
					break;
										
				default:
					success =  NO;
					break;
			}
			
			break;
			

		default:
			success =  NO;
			break;
			
	}
	
	if (conform) {
		
		if (success) {
			[self setRepresentation:representation];
		} else {
			MLogInfo(@"cannot conform to representation");
		}
	}
	
	
	return success;
}


@end
