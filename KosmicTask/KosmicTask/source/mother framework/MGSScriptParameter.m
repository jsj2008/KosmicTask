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
#import "MGSParameterPluginController.h"
#import "MGSAppController.h"

@implementation MGSScriptParameter


@synthesize modelDataModified = _modelDataModified;

+ (NSString *)defaultDescription
{
	return NSLocalizedString(@"Enter input.", @"New parameter description");
}
/*
 
 create a new parameter
 
 */
+ (id)new
{
	MGSScriptParameter *parameter = [self newDict];
	
	[parameter setName:NSLocalizedString(@"Input", @"New input parameter name")];
	[parameter setDescription:[self defaultDescription]];
	
	// set default plugin class name
	MGSParameterPluginController *parameterPluginController = [[NSApp delegate] parameterPluginController];
	NSString *pluginClassName = [parameterPluginController defaultPluginName];
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
 
 set value
 
 */
- (void)setValue:(id)object
{
	[self setObject:object forKey:MGSScriptKeyValue];
}

/*
 
 mutable copy with zone
 
 */
- (id)mutableCopyWithZone:(NSZone *)zone
{
	id aCopy = [super mutableCopyWithZone:zone];
	
	// copy local instance variables here
	 
	return aCopy;
}

/*
 
 mutable deep copy
 
 */
- (id)mutableDeepCopy
{
	id aCopy = [super mutableDeepCopy];
	
	// copy local instance variables here
	
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
