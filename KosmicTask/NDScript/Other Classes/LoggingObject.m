/*
 *  LoggingObject.m
 *  NDScriptData
 *
 *  Created by Nathan Day on 16/12/04.
 *  Copyright (c) 2002 Nathan Day. All rights reserved.
 */

#import "LoggingObject.h"
#import "ApplicationDelegate.h"
#import "NSString+NDUtilities.h"

static NSString		* kLoggingObjectKey = @"loggingObject",
					* kLogEntryKey = @"orderedEntries";

@implementation NSString (LoggingObject)
- (NSString *)prepareForLoggingObject
{
#if MAC_OS_X_VERSION_10_5 <= MAC_OS_X_VERSION_MAX_ALLOWED
	return [[self stringByReplacingOccurrencesOfString:@"\n" withString:@"\n\t\t"] stringByReplacingOccurrencesOfString:@"\r" withString:@"\n\t\t"];
#else
	return [[self stringByReplacingString:@"\n" withString:@"\n\t\t"] stringByReplacingString:@"\r" withString:@"\n\t\t"];
#endif
}
@end

@implementation LoggingObject

- (id)initWithDelegate:(ApplicationDelegate *)aDelegate
{
	if( (self = [self init]) != nil )
	{
		NSParameterAssert( aDelegate != nil );
		applicationDelegate = aDelegate;
	}
	return self;
}

#ifndef __OBJC_GC__

- (void)dealloc
{
	[orderedEntries release];
	[super dealloc];
}
#endif

- (void)logMessage:(NSString *)aMessage
{
	[applicationDelegate logMessage:aMessage];
	[self loggingEntryWithType:logType message:aMessage];
}

- (void)errorMessage:(NSString *)aMessage
{
	[applicationDelegate errorMessage:aMessage];
	[self loggingEntryWithType:errorType message:aMessage];
}

- (void)logFormat:(NSString *)aMessage, ...
{
	va_list	theArgList;
	va_start( theArgList, aMessage );
	[self logMessage:[NSString stringWithFormat:aMessage arguments:theArgList]];
	va_end( theArgList );
}

- (void)errorFormat:(NSString *)aMessage, ...
{
	va_list	theArgList;
	va_start( theArgList, aMessage );
	[self errorMessage:[NSString stringWithFormat:aMessage arguments:theArgList]];
	va_end( theArgList );
}

- (NSString*)contents
{
	return [applicationDelegate logContent];
}

- (unsigned long)numberOfScriptLoggings
{
	return numberOfScriptLoggings;
}

- (void)resetNumberOfScriptLoggings
{
	numberOfScriptLoggings = 0;
}


- (NSScriptObjectSpecifier *)objectSpecifier
{
	return [[[NSPropertySpecifier allocWithZone:[self zone]] initWithContainerClassDescription:[[NSScriptSuiteRegistry sharedScriptSuiteRegistry] classDescriptionWithAppleEventCode:cApplication] containerSpecifier:[[NSApplication sharedApplication] objectSpecifier] key:kLoggingObjectKey] autorelease];
}

- (NSString *)description
{
	return ( [applicationDelegate loggingObject] == self ) ? @"Applications Logging Object" : @"NOT the applications Logging Object";
}

- (LoggingEntry *)loggingEntryWithType:(enum LogType)aType message:(NSString *)aMessage
{
	if( orderedEntries == nil )
		orderedEntries = [[NSMutableArray alloc] init];
	
	if( aType == scriptType )
		numberOfScriptLoggings++;
	
	LoggingEntry	* theEntry = [LoggingEntry loggingEntryWithLoggingObject:self type:aType message:aMessage index:[orderedEntries count]];
	[orderedEntries addObject:theEntry];
	return theEntry;
}

- (unsigned int)indexOfLoggingEntryIdenticalTo:(LoggingEntry *)anEntry
{
	return [orderedEntries indexOfObjectIdenticalTo:anEntry];
}

- (NDScriptContext *)attachedScriptData
{
	return script;
}

- (void)setAttachedScriptData:(NDScriptContext *)aScript
{
	if( aScript != script )
	{
		[script release];
		script = [aScript retain];
		[script setParentObject:self];
	}
}

@end

@implementation LoggingObject (Scripting)

- (void)handleDisplayScriptCommand:(NSScriptCommand*)aCommand
{
	NSString		* theMessage = [[aCommand evaluatedArguments] objectForKey:@"Message"];
	if( theMessage )
	{
		[self loggingEntryWithType:scriptType message:theMessage];
		theMessage = [theMessage prepareForLoggingObject];
		[applicationDelegate logScriptMessage:[NSString stringWithFormat:@"script:\t%@", theMessage]];
	}
}

- (NSArray *)orderedEntries
{
	return orderedEntries;
}

- (unsigned int)orderedEntriesCount
{
	return [orderedEntries count];
}

- (LoggingEntry *)valueInOrderedEntriesAtIndex:(unsigned int)anIndex
{
	return [orderedEntries objectAtIndex:anIndex];
}

/*
 * -insertInOrderedEntries:
 */
- (void)insertInOrderedEntries:(LoggingEntry *)aValue
{
	NSString		* theMessage = [[aValue message] prepareForLoggingObject];
	[applicationDelegate logScriptMessage:[NSString stringWithFormat:@"script:\t%@", theMessage]];
	[self loggingEntryWithType:scriptType message:theMessage];
}

/*
 * -coerceValueForOrderedEntries:
 */
- (id)coerceValueForOrderedEntries:(id)aValue
{
	return nil;
}

/*
 * -scriptDescriptor
 */
- (NSAppleEventDescriptor *)scriptDescriptor
{
	return [[self attachedScriptData] appleEventDescriptorValue];
}

/*
 * -setScriptDescriptor:
 */
- (void)setScriptDescriptor:(NSAppleEventDescriptor *)aScriptDescriptor
{
	[self setAttachedScriptData:[NDScriptData scriptDataWithAppleEventDescriptor:aScriptDescriptor]];
}

@end

/*
 * @implementation LoggingEntry
 */
@implementation LoggingEntry

+ (id)loggingEntryWithLoggingObject:(LoggingObject *)aLoggingObject type:(enum LogType)aType message:(NSString *)aMessage index:(unsigned int)anIndex
{
	return [[[self alloc] initWithLoggingObject:aLoggingObject type:aType message:aMessage index:anIndex] autorelease];
}

- (id)initWithLoggingObject:(LoggingObject *)aLoggingObject type:(enum LogType)aType message:(NSString *)aMessage index:(unsigned int)anIndex
{
	if( (self = [self init]) != nil )
	{
		NSParameterAssert( [aLoggingObject isKindOfClass:[LoggingObject class]] );
		loggingObject = aLoggingObject;
		type = aType;
		message = [aMessage retain];
		index = anIndex;
	}
	return self;
}

#ifndef __OBJC_GC__
- (void)dealloc
{
	[message release];
	[super dealloc];
}
#endif

- (LoggingObject *)loggingObject
{
	return loggingObject;
}

- (enum LogType)type
{
	return type;
}

- (NSString *)message
{
	return message;
}

- (unsigned int)index
{
	return index;
}

- (NSString *)description
{
	static const char		* numberExten[] = {"th", "st", "nd", "rd", "th", "th", "th", "th", "th", "th"};
	LoggingObject	* theAppsLoggingObject = [[[NSApplication sharedApplication] delegate] loggingObject];
	unsigned int		theIndex = [theAppsLoggingObject indexOfLoggingEntryIdenticalTo:self];
	if( theIndex != NSNotFound )
	{
		const char	* theExten = theIndex%100 < 10 || theIndex%10 > 12 ? numberExten[theIndex+1 % 10] : numberExten[0];
		return [NSString stringWithFormat:@"%u%s entry (index=%u) of the applications logging object", theIndex+1, theExten, theIndex ];
	}
	else
		return @"Not an entry of the logging object";

}

- (NSScriptObjectSpecifier *)objectSpecifier
{
	NSScriptObjectSpecifier		* theContainerSpecifer = [[self loggingObject] objectSpecifier];
	return [[[NSIndexSpecifier allocWithZone:[self zone]] initWithContainerClassDescription:[theContainerSpecifer keyClassDescription] containerSpecifier:theContainerSpecifer key:kLogEntryKey index:[self index]] autorelease];
}

@end

