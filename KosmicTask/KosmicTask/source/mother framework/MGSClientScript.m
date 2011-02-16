//
//  MGSClientScriptHandler.m
//  Mother
//
//  Created by Jonathan Mitchell on 29/12/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSClientScript.h"
#import "MGSNetRequest.h"
#import "MGSNetMessage.h"
#import "MGSScriptPlist.h"

// script plist filename and location
NSString *MGSScriptsPlist = @"MotherScripts";
NSString *MGSScriptsPath = @"/Library/Application Support/Mother/";
NSString *MGSScriptsUserPath =  @"~/Library/Application Support/Mother/";

@interface MGSClientScript (Private)
- (void)copyDefaultPlistToFolder:(NSString *)folder;
- (void)copyDefaultScriptsToFolder:(NSString *)folder;
- (BOOL)executeScript:(NSDictionary *)script forRequest:(MGSNetRequest *)netRequest;
- (void)sendRequestReply:(MGSNetRequest *)netRequest;
@end

@implementation MGSClientScript

- (MGSClientScript *)init
{
	if (self = [super init]) {
		[self loadDictionary];
		_scriptTasks = [[NSArray alloc] init];
	}
	return self;
}

- (NSDictionary *)dictionary
{
	// return immutable copy of dictionary
	NSDictionary *dict = [NSDictionary dictionaryWithDictionary:_scriptsDictionary];
	return dict;
}

- (NSData *)dictionaryAsData
{
	// serialise the dict
	NSString *error;
	NSData *data = [NSPropertyListSerialization dataFromPropertyList:_scriptsDictionary
												format:NSPropertyListXMLFormat_v1_0
												errorDescription:&error];
	if (error) {
		MLog(@"error is: %@", error);
	}
	
	return data;
}

// load or reload the scripts dictionary
- (BOOL)loadDictionary
{
	// load the dictionary from file
	NSString *filePath = [[self path] stringByAppendingPathComponent: MGSScriptsPlist];
	filePath = [filePath stringByAppendingPathExtension:@"plist"];
	_scriptsDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:filePath];
	
	if (!_scriptsDictionary) {
		MLog(@"could not load scripts dictionary at %@", filePath);
		return NO;
	}
	
	return YES;
}

// parse net request for script activity
- (BOOL)parseNetRequest:(MGSNetRequest *)netRequest
{
	NSAssert([netRequest delegate], @"net request delegate is nil");
	
	MGSNetMessage *requestMessage = [netRequest requestMessage];
	MGSNetMessage *replyMessage = [netRequest replyMessage];
	
	NSMutableDictionary *requestDict = [requestMessage messageDict];
	NSDictionary *scriptDict;
	
	// all script actions will be contained in the motherscript dictionary
	id obj = [requestDict objectForKey:MGSScriptKeyMotherScript];	
	if ([obj isKindOfClass: [NSDictionary class]]) {
		scriptDict = obj;
	} else {
		return NO;
	}
	
	// parse the script command
	NSString *command = [scriptDict objectForKey:MGSScriptKeyCommand];
	if (!command) {
		return NO;
	}
		
	// get list of the available scripts
	if ([command isEqualToString:MGSScriptCommandList]) {
		if (!_scriptsDictionary) {
			return NO;
		}
		
		// add scripts dict to reply, flag as valid and send
		[replyMessage setMessageObject:_scriptsDictionary forKey:MGSScriptKeyMotherScript];
		[self sendRequestReply:netRequest];
	}
	
	// execute a given script
	else if ([command isEqualToString:MGSScriptCommandExecute]) {
		[self executeScript:[scriptDict objectForKey:MGSScriptKeyScript] forRequest: netRequest];
	}

	return YES;
}

// path to application support scripts
- (NSString *) path
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
    
	NSString *folder = MGSScriptsPath;
	
	// ensure the path exists
	if ([fileManager fileExistsAtPath: folder] == NO)
	{
		[fileManager createDirectoryAtPath: folder attributes: nil];
		[self copyDefaultScriptsToFolder: folder];
	}

	// ensure that the default plist always exists
	[self copyDefaultPlistToFolder: folder];
	
	return folder;
}

// path to user application support scripts
- (NSString *) userPath
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
    
	NSString *folder = MGSScriptsUserPath;
	folder = [folder stringByExpandingTildeInPath];
	
	if ([fileManager fileExistsAtPath: folder] == NO)
	{
		[fileManager createDirectoryAtPath: folder attributes: nil];
	}
    
	//NSString *fileName = @"MailDemo.cdcmaildemo";
	//return [folder stringByAppendingPathComponent: fileName]; 
	return folder;
}
@end

@implementation MGSClientScript (MGSTaskDelegate)

- (void) taskDidTerminate:(id)aTask
{
	MGSScriptTask *scriptTask = aTask;
	[_scriptTasks removeObject:scriptTask];
	[self sendRequestReply: [scriptTask netRequest]];
}

@end

//
// Private category
//
@implementation MGSClientScript (Private)

 - (void)sendRequestReply:(MGSNetRequest *)netRequest

 {	
	 id delegate = [netRequest delegate];
	 
	 NSAssert(delegate, @"delegate is nil");
	 
	 // tell net request delegate to send reply
	 if (delegate && [delegate respondsToSelector:@selector(sendRequestReply:)]) {
		[delegate sendRequestReply:netRequest];
	 }
 }

- (BOOL)executeScript:(NSDictionary *)script forRequest:(MGSNetRequest *)netRequest
{
	NSAssert(script, @"script is nil");
	NSAssert(netRequest, @"net request is nil");	
	
	NSString *error;
	
	// this dictionary will be added to the reply
	NSMutableDictionary *replyDict = [NSMutableDictionary dictionaryWithCapacity:2];
	
	// script file to execute	
	NSString *scriptFile = [script objectForKey: MGSScriptKeyScriptFile];
	if (!scriptFile) {
		error = NSLocalizedString(@"Execute file not defined", @"Returned by server when script file not defined in request");
		goto errorExit;
	}
	
	// validate script path
	NSString *scriptPath = [[[self path] stringByAppendingPathComponent:scriptFile] stringByAppendingPathExtension:@"scpt"];
	if (![[NSFileManager defaultManager] fileExistsAtPath:scriptPath]) {
		error = NSLocalizedString(@"Execute file cannot be found", @"Returned by server when script file not found");
		goto errorExit;
	}
	
	// task will read dict from std in
	NSMutableDictionary *taskDict = [NSMutableDictionary dictionaryWithCapacity:2];
	
	// path to script
	[taskDict setObject:scriptPath forKey:MGSScriptPath];
	
	// copy script parameter array details to task array
	// these must be NSNumber or NSString only
	// each item in script parameter array must by an NSDictionary
	NSMutableArray *taskParamArray = [NSMutableArray arrayWithCapacity:2];
	NSArray *scriptParamArray = [script objectForKey: MGSScriptKeyParameters];
	for (id item in scriptParamArray) {
		
		// get individual script parameter dictionary
		if (![item isKindOfClass:[NSDictionary class]]) {
			error = NSLocalizedString(@"Script parameter list malformed", @"Returned by server when script parameter data is malformed");
			goto errorExit;
		}
		NSDictionary *params = (NSDictionary *)item;
		
		// get parameter value, if missing use default
		NSString *value = [params objectForKey:MGSScriptKeyValue];
		if (!value) {
			value = [params objectForKey:MGSScriptKeyDefault];
		}
		if (!value) {
			error = NSLocalizedString(@"No value found for parameter", @"Returned by server when script parameter value is missing");
			goto errorExit;
		}
		
		// get parameter type
		NSString *valueType = [params objectForKey:MGSScriptKeyType];
		if (!valueType) {
			error = NSLocalizedString(@"No value type found for parameter", @"Returned by server when script parameter value type is missing");
			goto errorExit;
		}

		// NSAppleScript will only accept NSNumber and NSString as parameters to a script
		//
		// integer parameter
		if ([valueType isEqualToString:MGSScriptTypeInteger]) {
			[taskParamArray addObject:[NSNumber numberWithInteger: [value integerValue]]];

		// double parameter
		} else if ([valueType isEqualToString:MGSScriptTypeDouble]) {
			[taskParamArray addObject:[NSNumber numberWithDouble: [value doubleValue]]];
				
		// string parameter
		} else if ([valueType isEqualToString:MGSScriptTypeString]) {
			[taskParamArray addObject:value];
		}
			
		// invalid parameter type
		else {
			error = NSLocalizedString(@"Invalid parameter value type", @"Returned by server when script value type is invalid");
			goto errorExit;
		}
	}
	[taskDict setObject:taskParamArray forKey:MGSScriptParameters];
	//MLog(@"task param array: %@", taskParamArray);
		 
	// serialise the dict so that it can be sent to the task's stdin
	NSString *plistError;
	NSData *taskData = [NSPropertyListSerialization dataFromPropertyList:taskDict
																  format:NSPropertyListXMLFormat_v1_0
														errorDescription:&plistError];
	
	NSAssert(taskData, @"script task dictionary nil");
	
	// start the script task
	MGSScriptTask *scriptTask = [[MGSScriptTask alloc] init];
	[scriptTask setDelegate: self];
	
	NSError *err = nil;
	if (![scriptTask start:taskData withError:&err]) {
		error = [err localizedDescription];
		goto errorExit;
	}

	// add to script tasks array
	[_scriptTasks addObject:scriptTask];
	
	return YES;
	
errorExit:
	// insert error into reply script dict
	[replyDict setObject:error forKey:MGSScriptKeyError];
	[[netRequest replyMessage] setMessageObject:replyDict forKey:MGSScriptKeyMotherScript];
	
	return NO;
}

// copy the default scripts plist to the folder if
// it does not already exist
- (void)copyDefaultPlistToFolder:(NSString *)folder
{
	NSAssert(folder, @"folder is nil");
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	// check if target file already exists
	NSString *targetFile = [folder stringByAppendingPathComponent: MGSScriptsPlist];
	targetFile = [targetFile stringByAppendingPathExtension:@"plist"];
	if ([fileManager fileExistsAtPath: targetFile]) {
		return;
	}
	
	// get default plist from bundle 
	NSBundle *bundle = [NSBundle mainBundle];
	NSString *path = [bundle pathForResource:MGSScriptsPlist ofType:@"plist"];
	
	if (!path) {
		MLog(@"Cannot find %@.plist in bundle", MGSScriptsPlist);
		return;
	}
	
	// copy file to folder
	NSError *error;
	if (![fileManager copyItemAtPath:path toPath:targetFile error:&error]) {
		MLog(@"Cannot copy bundled %@ to %@ : error is : %@", path, targetFile, [error localizedDescription]);
	}
	
	return;
}

// copy the default scripts from application bundle to the folder if
// they do not already exist
- (void)copyDefaultScriptsToFolder:(NSString *)folder
{
	NSAssert(folder, @"folder is nil");
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	// get path to app bundle scripts folder and enumerate contents
	NSString *path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"scripts"];
	NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:path];
	
	NSString *scriptFile;
	while (scriptFile = [dirEnum nextObject]) {
		
		// want to copy files only
		if ([[[dirEnum fileAttributes] objectForKey:NSFileType] isEqualToString: NSFileTypeRegular]) {
			
			// check if target file already exists
			NSString *targetFile = [folder stringByAppendingPathComponent: scriptFile];
			if ([fileManager fileExistsAtPath: targetFile]) {
				continue;
			}
			
			// copy script file to folder
			NSString *sourceFile = [path stringByAppendingPathComponent: scriptFile];
			NSError *error;
			if (![fileManager copyItemAtPath:sourceFile toPath:targetFile error:&error]) {
				MLog(@"Cannot copy script %@ to %@ : error is : %@", sourceFile, targetFile, [error localizedDescription]);
			}
		}
	}
	
	return;
}





@end
