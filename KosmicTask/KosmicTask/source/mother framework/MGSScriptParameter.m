//
//  MGSScriptParameter.m
//  Mother
//
//  Created by Jonathan on 09/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//


#import "MGSScriptParameter.h"
#import "MGSScriptPlist.h"
#import "MGSParameterPluginController.h"
#import "MGSAppController.h"
@implementation MGSScriptParameter


@synthesize modelDataModified = _modelDataModified;

/*
 
 create a new parameter
 
 */
+ (id)new
{
	MGSScriptParameter *parameter = [self newDict];
	
	[parameter setName:NSLocalizedString(@"New", @"New parameter name")];
	[parameter setDescription:NSLocalizedString(@"New input", @"New parameter description")];
	
	// set default plugin class name
	MGSParameterPluginController *parameterPluginController = [[NSApp delegate] parameterPluginController];
	NSString *pluginClassName = [parameterPluginController defaultPluginName];
	[parameter setTypeName:pluginClassName];
	
	// create class info mutable dict
	// note that we use assign rather than set.
	// set will create a copy of our object by default.
	// and that copy will be immutable.
	[parameter assignObject:[NSMutableDictionary dictionaryWithCapacity:2] forKey:MGSScriptKeyClassInfo];
	 
	return parameter;
}

/*
 
 init
 
 */
- (id)init
{
	[super init];
	_modelDataModified = NO;
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
 
 we do not provide a setted here as our overridden default implementation of 
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

@end
