//
//  mlog.m
//  mother
//
//  Created by Jonathan Mitchell on 27/09/2007.
//  Copyright 2007 www.mugginsoft.com. All rights reserved.
//
// Calling NSLog from multiple processes
//
// see: http://www.cocoabuilder.com/archive/message/cocoa/2003/6/16/3689
#import <sys/stat.h>
#import "mlog.h"
#import "MGSPreferences.h"

static MLog *_sharedController = nil;

//
// std C functions
// created by JM

static NSUInteger _logFilePosition = 0;


@implementation MLog

@synthesize recycle = _recycle;
@synthesize aslFacilityName = _aslFacilityName;
@synthesize aslSender = _aslSender;

/*
 
 shared controller
 
 */
+ (id)sharedController
{
	if (nil == _sharedController) {
		_sharedController = [[self alloc] init];
	}
	return _sharedController;
}

/*
 
 init
 
 */
- (id)init
{
	if ((self = [super init])) {



#ifdef MUGGINSOFT_BETA		
		_MLogLevel = RELEASELOG;	
#else
		_MLogLevel = RELEASELOG;	
#endif	
		
		_MLogConsoleOnlyLogging = NO;
				
		// asl
		_aslMessage = NULL;
		_aslFacilityName = @"com.mugginsoft.kosmictask";
		_aslSender = NULL;
		_aslClient = NULL;
		//[self openAslLog];

		// load defaults
		[self loadDefaults];

		// recycle the logfile
		_recycle = NO;
	}
	
	return self;
}

/*
 
 open asl log
 
 */
- (void)openAslLog
{	
	// asl client
	_aslClient = asl_open([_aslSender cStringUsingEncoding:NSUTF8StringEncoding], 
						  [_aslFacilityName cStringUsingEncoding:NSUTF8StringEncoding], 
						  ASL_OPT_STDERR);
	NSString *logFilePath = MLogFilePath();
	int fd = open([logFilePath cStringUsingEncoding:NSUTF8StringEncoding], O_RDWR);
	asl_add_log_file(_aslClient, fd);
	
	// default message
	_aslMessage = asl_new(ASL_TYPE_MSG);
	
	// default message keys and values
	if (_aslSender != NULL) {
		
		// if sender not set will default to process name
		asl_set(_aslMessage, ASL_KEY_SENDER, [_aslSender cStringUsingEncoding:NSUTF8StringEncoding]);
	}
}
		
/*
 
 start timer
 
*/
- (void)startTimer
{
	// the logging defaults may be changed throughout the lifetime of this object.
	// plus there may be instances if this class runnig in different processes that needed to
	// be synced to the same set of defaults.
	// hence do a poll to reload the defaults.
	_timer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(timerExpired:) userInfo:NULL repeats:YES];
}

/*
 
 recycle the log file
 
 */
- (void)doRecycle
{
	// if log greater than limit then cycle
	NSString *logPath = MLogFilePath();
	NSFileManager *nsfm = [NSFileManager defaultManager];
	if (![nsfm fileExistsAtPath:logPath]) {
		return;
	}
	
	NSDictionary *fsAttributes = [nsfm attributesOfItemAtPath:logPath error:NULL];
	NSNumber * fileSize;
	if ((fileSize = [fsAttributes objectForKey:NSFileSize])) {
		if ([fileSize unsignedLongLongValue] < kMLogMaxFileSize) {
			return;
		}
	} else {
		return;
	}
	
	// copy the log file
	NSString *logPathCycled = [NSString stringWithFormat: @"%@.prev.log", logPath];
	[nsfm removeItemAtPath:logPathCycled error:NULL];
	[nsfm copyItemAtPath:logPath toPath:logPathCycled error:NULL];
	
	// now clear it
	[self clear];
	
	return;
}

/*
 
 load defaults
 
 */
- (void)loadDefaults
{
	MGSPreferences *defaults = [MGSPreferences standardUserDefaults];
	
	[self setDebugLoggingEnabled: [defaults boolForKey:MGSEnableDebugLogging]];	
	_MLogConsoleOnlyLogging = [defaults boolForKey:MGSEnableLoggingToConsoleOnly];
	_MLogMaxEntryLength = (NSUInteger)[defaults integerForKey:MGSMaxLogEntryLength];
	
	
	// sanity check 
	if (_MLogMaxEntryLength <= 0) _MLogMaxEntryLength = MGS_MAX_LOG_ENTRY_LENGTH;
	
	// redirect stderr
	// note that redirecting stderr mucks up NSLog and unit test output
	MLogFileRedirectStdErr(!_MLogConsoleOnlyLogging);
}

/*
 
 set debug logging enabled
 
 */
- (void)setDebugLoggingEnabled:(BOOL)value
{
	_MLogLevel = value ? DEBUGLOG : RELEASELOG;	
}

/*
 
 log with level, sourcefile, line number, format and arguments
 
 */
- (BOOL)withLevel:(int)level sourceFile:(char *)sourceFile lineNumber:(int)lineNumber format:(NSString *)format, ...
{
	@try {
		
		@synchronized(self) {
			
		// MUGGINSOFT_DEBUG defined in project preprocessor macros for debug build
		#ifndef MUGGINSOFT_DEBUG
			// debug only
		#endif

			if (level == MEMORYLOG) {
				return NO;
			}
			
			// discard debug events in releaselevel
			if (_MLogLevel == RELEASELOG && level != RELEASELOG) {
				return NO;
			}
			
			
			// get filename string
			NSString * filename = [[NSString alloc] initWithBytes:sourceFile 
											length:strlen(sourceFile) 
										  encoding:NSUTF8StringEncoding];
			NSString *logEntry = @"";
			
			// read variable argument list
			va_list ap;
			va_start(ap,format);
			
			// note that exception was being thrown here as format
			// was NSPlaceholderString, an abstract NSString class
			if (![format isKindOfClass:[NSString class]]) {
				logEntry = @"invalid format string";
				format = @"";
			} else {
				
				// if the format specifier contains more %@ attributes than the ap can supply
				// then an exception is thrown.
				// this can occur when the actual error string contains things like
				// OSX::NSLog("%@", @"error")
				// which can get generated when compiling up the likes of RubyCocoa.
				// the va_list gets searched for additional items (to match the unanticipated format specifiers)
				// that are invalid and a runtime exception occurs
				 logEntry = [[NSString alloc] initWithFormat:format arguments:ap];
			}
			va_end(ap);
			
			// truncate entry if too long
			if ([logEntry length] > _MLogMaxEntryLength) {
				NSString *suffix = [NSString stringWithFormat:@"this entry truncated: from %u to %u bytes", [logEntry length], _MLogMaxEntryLength];
				NSString *entryStart = [logEntry substringToIndex:_MLogMaxEntryLength/2];
				NSString *entryEnd = [logEntry substringFromIndex:[logEntry length] - _MLogMaxEntryLength/2];
				logEntry = [NSString stringWithFormat: @"%@\n\n *** entry data omitted here *** \n\n%@\n*** %@\n", entryStart, entryEnd, suffix];
			}
					
			// show filename and linenumber if supplied
			if (![filename isEqualToString:@""]) {
				logEntry = [NSString stringWithFormat: @"%s:%d %@",[[filename lastPathComponent] UTF8String], lineNumber, logEntry];
			} 
			
			// log it
			if (_aslClient == NULL) {
				NSLog(@"%@", logEntry);
			} else {
				asl_log(_aslClient, _aslMessage, ASL_LEVEL_ERR, [logEntry cStringUsingEncoding:NSUTF8StringEncoding], nil);
			}
		}
	
	}
	@catch (NSException * e) {
		NSLog(@"Exception while logging: %@", [e description]);
	}
	
	
	return YES;
}

/*
 
 set log level
 
 */
- (void)setLevel:(int)level
{
	_MLogLevel=level;
}

/*
 
 log file recent text
 
 */
 - (NSString *)logFileRecentText
 {
	 return [self logFileTextStartingAtLocation:_logFilePosition];
 }
 
/*
 
 log file text
 
 */
- (NSString *)logFileText
{
	NSString *logText = [NSString stringWithContentsOfFile: MLogFilePath() encoding:NSUTF8StringEncoding error: NULL];
	if (!logText) {
		logText = @"Log text could not be retrieved";
	}
	return logText;
}

/*
 
 get log text at location

*/ 
- (NSString *)logFileTextStartingAtLocation:(NSUInteger)location
{
	NSFileHandle *logFile;
	NSFileManager *nsfm;
	NSString *logString = nil;
	NSString *logPrefix = nil;
	NSString *logPath = MLogFilePath();
	nsfm = [NSFileManager defaultManager];
	
	NSDictionary *attributes = [nsfm attributesOfItemAtPath:logPath error:NULL];
	if (!attributes)  {
		return @"*** Log file not found. ***\n";
	}
	
	// file size is 64 bit, but the rest of our 32 bit methods cannot really handle this
	NSNumber *fileSizeNum = [attributes objectForKey:NSFileSize];
	//unsigned long long fileSize = [fileSizeNum unsignedLongLongValue];
	NSUInteger fileSize = [fileSizeNum unsignedIntegerValue];
	
	if (location > fileSize) {
		logPrefix = [NSString stringWithFormat: @"*** Log file size appears to be incorrect. Location = %u Filesize = %u ***\n", location, fileSize];
	}
	
	// open file
	logFile = [NSFileHandle fileHandleForReadingAtPath:logPath];
	if (!logFile) {
		return @"*** Log file not found. ***\n";
	}
	
	// 
	@try {
		[logFile seekToFileOffset:location];	// raises exception on error
		_logFilePosition = fileSize;
		NSUInteger dataLength = _logFilePosition - location;
		NSData *data = [logFile readDataOfLength:dataLength];	// raises exception on error
		logString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	}
	@catch (NSException * exception) {
		NSLog (@"Exception reading log file: %@", [exception name]);
	}
	@finally {
		[logFile closeFile];
	}
	
	if (logPrefix) {
		logString = [logPrefix stringByAppendingString:logString];
	}
	
	if (!logString) {
		logString = @"previous log not found\n";
	}
	
	return logString;
}

/*
 
 path to logfile
 
 */
- (NSString *)path
{
	return MLogFilePath();
}

/*
 
 clear the log
 
 */
- (BOOL)clear
{	
	@try {
		
		// removing the file causes output from other process that share the log to be lost
		//BOOL success = [[NSFileManager defaultManager] removeFileAtPath:[self path] handler:nil];
		BOOL success = ftruncate(STDERR_FILENO, 0) == 0 ? YES : NO;
		if (success) {
			_logFilePosition = 0;
			if (!_MLogConsoleOnlyLogging) {				
				NSLog([NSString stringWithFormat:@"log created: %@\n", [NSDate date]], nil);
			}
			
		} else {
			NSLog(@"*** Could not truncate log. ***\n");
		}
		
		return success;
	}
	@catch (NSException * exception) {
		NSLog (@"Exception deleting log file: %@\n", [exception name]);
	}
	
	return NO;
}
/*
 
 timerExpired
 
 */
- (void)timerExpired:(NSTimer *)aTimer
{	
#pragma unused(aTimer)
	[self loadDefaults];
	
	if (self.recycle) {
		
		// recycle the logfile
		[self doRecycle];
		
	}
}

@end

//
// functions
//

/*
 
 send std error to logfile
 
 note that duplicating stderror has the side effect of interfering with ftruncate().
 
 */
void MLogFileRedirectStdErr(BOOL redirect)
{
	static int stderrSave = -1;
	static BOOL redirectState = NO;
	
	if (redirect == redirectState) {
		return;
	}
	
	if (redirect) {
		// Set permissions for our NSLog file
		umask(022);
		
		// Save stderr so it can be restored.
		
		 //has undesirable side effect 
		 stderrSave = dup(STDERR_FILENO);
		
		
		NSString *logPath = MLogFilePath();
		
		// note that specifying a makes write operations to the stream atomic.
		// see Steven's Advanced Unix Programming for details.
		freopen([logPath fileSystemRepresentation], "a", stderr);

	} else {
		
		
		//has undesirable side effect 
		// Flush before restoring stderr
		fflush(stderr);
		
		// Now restore stderr, so new output goes to console.
		dup2(stderrSave, STDERR_FILENO);
		close(stderrSave);
		 
		 
	}
	
	redirectState = redirect;
	
	return;
}

/*
 
 logfile path
 
 */
NSString * MLogFilePath()
{
	//NSString *applicationName = [NSString stringWithFormat: @"Library/Logs/%@.log", [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleName"]];
	NSString *applicationName = [NSString stringWithFormat: @"Library/Logs/%@.log", @"KosmicTask"];
	NSString *logPath = [NSHomeDirectory() stringByAppendingPathComponent:applicationName];
	
	return logPath;
}

/*
 
 write to logfile
 
 */
void MLogFileWrite(NSString *logEntry)
{
	NSFileHandle *logFile;
	NSFileManager *nsfm;
	NSString *logThis;
	
	// recycle the log file
	//MLogFileRecycle();	// observing this in the error window is tricky
	
	NSString *logPath = MLogFilePath();
	nsfm = [NSFileManager defaultManager];
	
	// create log file if it doesn't exist
	if (![nsfm fileExistsAtPath:logPath]) {
		logThis = [NSString stringWithFormat:@"log created: %@\n", [NSDate date]];
		if (![nsfm createFileAtPath:logPath contents:[logThis dataUsingEncoding:NSUTF8StringEncoding] attributes:nil]) {
			NSLog(@"Cannot create logfile");
			return;
		}
	}
	
	// a nil entry may be used when creating new log
	if (!logEntry) {
		return;
	}
	
	// open file
	logFile = [NSFileHandle fileHandleForWritingAtPath:logPath];
	if (!logFile) {
		return;
	}
	[logFile seekToEndOfFile];
	
	// writeData takes NSData
	// prepend date string
	logThis = [NSString stringWithFormat: @"%@ : %@\n", [NSDate date], logEntry];
	NSData *logData = [logThis dataUsingEncoding:NSUTF8StringEncoding];
	@try {
		[logFile writeData:logData]; // raises exception on error
	}
	@catch (NSException * exception) {
		NSLog (@"Exception MLogFileWrite: %@", [exception name]);
	}
	@finally {
		[logFile closeFile];
	}
	
	return;
}



/*
 
 log NSRect
 
 */
void MLogRect(NSString *string, NSRect rect)
{
	string = [string stringByAppendingString:@" x = %f, y = %f, w = %f, h = %f"];
	NSLog(string, rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
}
