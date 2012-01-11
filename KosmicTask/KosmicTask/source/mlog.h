//
//  mlog.h
//  mother
//
//  Created by Jonathan Mitchell on 27/09/2007.
//  Copyright 2007 www.mugginsoft.com. All rights reserved.
//
// see http://www.borkware.com/rants/agentm/mlog/
//
/*
 
 Variadic macros allow the preprocessor to handle macro definitions with a variable number of 
 arguments. This is handy everywhere variadic functions are, such as NSLog(), which takes a 
 variable number of arguments. We, too, can define variadic functions and macros. 
 See the GCC page on variadic macros for important information on portability and standards. 
 Since I assume everyone is using a recent version of gcc, I took the liberty of using a GCC
 extension to the standard.
 
 The MLogString macro should simply call +logFile:lineNumber:format: with everything required. 
 Some macro magic will help us get exactly what we need. Here's the code:
 
#define MLogString(s,...) \
 [MLog logFile:__FILE__ lineNumber:__LINE__ \
		format:(s),##__VA_ARGS__]
 This simple macro covers it, but let's look at exactly what is going on here. 
 First, #define tells the preprocessor that we are defining a macro which is recognized as 
 MLogString(s,...). This means the prepocessor will look for code which looks like the function
 call MLogString(). The preprocessor must also recognize that the macro takes a variable number
 of arguments.
 
 The second half of the declaration define what the "function" should be replaced with. Clearly, we want to send a message to MLog, so we do that, but include some strange looking arguments. In fact, these arguments are themselves macros. __FILE__ is replaced with the current sourcecode file name and __LINE__ is replaced with the current line number in that source file. ##__VA_ARGS__ is a special preprocessor directive that lets the preprocessor know that it should fill in the variable arguments there. Note that this is a GNU GCC specific directive because it doesn't adhere to the C99 standard. This extension allows us to call MLogString() with only one string argument but still get meaningful output. See the GCC page on variadic macros for more information.
 So that's it! Now we have a NSLog() replacement that looks like NSLog() but adds line and file name information. Let's see what it can do:

MLog(DEBUGLOG, @"logged!");
2005-02-13 20:06:07.582 MyApp[1465] main.m:15 logged!
MLog(DEBUGLOG, @"logged an int %d",10);
2005-02-13 20:18:43.147 MyApp[1485] main.m:15 logged an int 10

 */
#import <Cocoa/Cocoa.h>
#include <asl.h>

#define RELEASELOG 0	// enable release logging
#define DEBUGLOG 1		// enable debug logging
#define MEMORYLOG 2	// enable memory logging

// generate debug log entry
// note that the correct calling format here is
// MLog(1, @"", @"error")
// if say MLog(1, var) then if var contains format specifiers the va_list will overflow
// so MLog(1, @"%@", var) is correct
#define MLog(level,s,...) [[MLog sharedController] withLevel:level sourceFile:__FILE__ lineNumber:__LINE__ format:(s),## __VA_ARGS__]

// generate informational log entry
#define MLogInfo(s,...) [[MLog sharedController] withLevel:RELEASELOG sourceFile:"" lineNumber:0 format:(s),## __VA_ARGS__]
#define MLogDebug(s,...) [[MLog sharedController] withLevel:DEBUGLOG sourceFile:__FILE__ lineNumber:__LINE__ format:(s),## __VA_ARGS__]

#define MLogException(e) MLogInfo(@"Exception : %@ %@", [e name], [e reason])

// don't let the log file get to big or the cost of scrolling the text
// in the error window becomes very heavy
// 1MB seems to be suitable
#define kMLogMaxFileSize 200000	// max log file size before recycling occurs

// std C functions
void MLogFileRedirectStdErr(BOOL redirect);
NSString * MLogFilePath();
void MLogFileWrite(NSString *logEntry);
extern void MLogRect(NSString *string, NSRect rect);

@interface MLog : NSObject
{
	int _MLogLevel;
	BOOL _MLogConsoleOnlyLogging;
	NSTimer *_timer;
	BOOL _recycle;
	aslclient _aslClient;
	aslmsg _aslMessage;
	NSString *_aslFacilityName;
	NSString *_aslSender;
	NSUInteger _MLogMaxEntryLength;
}

@property BOOL recycle;
@property (copy) NSString *aslFacilityName;
@property (copy) NSString *aslSender;

+ (id)sharedController;
- (BOOL)withLevel:(int)build sourceFile:(char*)sourceFile lineNumber:(int)lineNumber format:(NSString*)format, ...;
- (void)setLevel:(int)level;
- (void)setDebugLoggingEnabled:(BOOL)value;
- (NSString *)logFileTextStartingAtLocation:(NSUInteger)location;
- (NSString *)logFileRecentText;
- (NSString *)path;
- (BOOL)clear;
- (void)loadDefaults;
- (void)startTimer;
- (void)openAslLog;
- (void)doRecycle;
- (NSString *)logFileText;
- (void)timerExpired:(NSTimer *)aTimer;
@end
