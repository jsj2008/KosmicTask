/*!
	@header LoggingObject.h
	@abstract Header file from the project NDScriptData
	@discussion <#Discussion»
 
	Created by Nathan Day on 16/12/04.
	Copyright &#169; 2003 Nathan Day. All rights reserved.
 */
#import <Cocoa/Cocoa.h>
#import "NDScript.h"

@class		ApplicationDelegate,
				LoggingEntry;

@interface NSString (LoggingObject)
- (NSString *)prepareForLoggingObject;
@end

/*!
	@class LoggingObject
	@abstract <#Abstract#>
	@discussion <#Discussion#>
 */
@interface LoggingObject : NSObject
{
@private
	ApplicationDelegate		* applicationDelegate;
	NSMutableArray				* orderedEntries;
	NDScriptContext			* script;
	unsigned long				numberOfScriptLoggings;
}


- (id)initWithDelegate:(ApplicationDelegate *)delegate;
- (void)logMessage:(NSString *)message;
- (void)errorMessage:(NSString *)message;
- (void)logFormat:(NSString *)message, ...;
- (void)errorFormat:(NSString *)message, ...;

- (NSString*)contents;
- (unsigned long)numberOfScriptLoggings;
- (void)resetNumberOfScriptLoggings;

- (LoggingEntry *)loggingEntryWithType:(enum LogType)type message:(NSString *)message;
- (unsigned int)indexOfLoggingEntryIdenticalTo:(LoggingEntry *)entry;

- (NDScriptContext *)attachedScriptData;
- (void)setAttachedScriptData:(NDScriptContext *)script;

@end

@interface LoggingObject (Scripting)
- (void)handleDisplayScriptCommand:(NSScriptCommand*)aCommand;
- (NSArray *)orderedEntries;
- (unsigned int)orderedEntriesCount;
- (LoggingEntry *)valueInOrderedEntriesAtIndex:(unsigned int)index;
//- (void)replaceInOrderedEntries:(LoggingEntry *)value atIndex:(unsigned int)index;
//- (void)insertInOrderedEntries:(LoggingEntry *)value atIndex:(unsigned int)index;
//- (void)removeFromOrderedEntriesAtIndex:(unsigned int)index;
- (void)insertInOrderedEntries:(LoggingEntry *)value;
- (id)coerceValueForOrderedEntries:(id)value;
- (NSAppleEventDescriptor *)scriptDescriptor;
- (void)setScriptDescriptor:(NSAppleEventDescriptor *)scriptDescriptor;

@end

enum LogType
{
	logType,
	errorType,
	scriptType
};

@interface LoggingEntry : NSObject
{
@private
	LoggingObject	* loggingObject;
	enum LogType	type;
	NSString			* message;
	unsigned int	index;
}

+ (id)loggingEntryWithLoggingObject:(LoggingObject *)loggingObject type:(enum LogType)type message:(NSString *)message index:(unsigned int)s;

- (id)initWithLoggingObject:(LoggingObject *)loggingObject type:(enum LogType)type message:(NSString *)message index:(unsigned int)index;

- (LoggingObject *)loggingObject;
- (enum LogType)type;
- (NSString *)message;
- (unsigned int)index;

@end

