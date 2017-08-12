//
//  UKCrashReporter.m
//  NiftyFeatures
//
//  Created by Uli Kusterer on Sat Feb 04 2006.
//  Copyright (c) 2006 M. Uli Kusterer. All rights reserved.
//

// -----------------------------------------------------------------------------
//	Headers:
// -----------------------------------------------------------------------------

#import "UKCrashReporter.h"
#import "UKSystemInfo.h"
#import <AddressBook/AddressBook.h>

NSString*	UKCrashReporterFindTenFiveCrashReportPath( NSString* appName, NSString* crashLogsFolder );
BOOL UKValidateCrashLogFolder(NSString *crashLogsFolder);

// -----------------------------------------------------------------------------
//	UKCrashReporterCheckForCrash:
//		This submits the crash report to a CGI form as a POST request by
//		passing it as the request variable "crashlog".
//	
//		KNOWN LIMITATION:	If the app crashes several times in a row, only the
//							last crash report will be sent because this doesn't
//							walk through the log files to try and determine the
//							dates of all reports.
//
//		This is written so it works back to OS X 10.2, or at least gracefully
//		fails by just doing nothing on such older OSs. This also should never
//		throw exceptions or anything on failure. This is an additional service
//		for the developer and *mustn't* interfere with regular operation of the
//		application.
//
// Mugginsoft 16 June 08
// Added crashedAppName argument to enable crash detection for auxiliary executables.
// Not sure what will happen if two app components crash at the same time!
//
// Mugginsoft 18 August 08
// Added log file path argument.
//
// Mugginsoft 29 October 12
// Added support for OS X 10.8
// -----------------------------------------------------------------------------

void	UKCrashReporterCheckForCrash(NSString *crashedAppName, NSString *appLogFilePath)
{
	@autoreleasepool {
	
		NS_DURING
			// Try whether the classes we need to talk to the CGI are present:
			Class			NSMutableURLRequestClass = NSClassFromString( @"NSMutableURLRequest" );
			Class			NSURLConnectionClass = NSClassFromString( @"NSURLConnection" );
			if( NSMutableURLRequestClass == Nil || NSURLConnectionClass == Nil )
			{
				NS_VOIDRETURN;
			}
			
			SInt32	sysvMajor = 0, sysvMinor = 0, sysvBugfix = 0;
			UKGetSystemVersionComponents( &sysvMajor, &sysvMinor, &sysvBugfix );
			BOOL	isTenFiveOrBetter = sysvMajor >= 10 && sysvMinor >= 5;
			BOOL	isTenSixOrBetter = sysvMajor >= 10 && sysvMinor >= 6;
    
			// Get the crash log file, its last change date and last report date:
			NSString *		appName = crashedAppName;
			if (!appName) {
				appName = [[[NSBundle mainBundle] infoDictionary] objectForKey: @"CFBundleExecutable"];
			}
        NSString* crashLogsFolder = nil;
 
        // 10.6 +
        if (isTenSixOrBetter) {
            
            // Note: on 10.6 and 10.7 (but not above)
            // crash log folder path aliases in the pre 10.6 path point here.
            crashLogsFolder = [@"~/Library/Logs/DiagnosticReports/" stringByExpandingTildeInPath];
            if (!UKValidateCrashLogFolder(crashLogsFolder)) {
                return;
            }
        } else {
    
            // pre 10.6 crash log folder path
            crashLogsFolder = [@"~/Library/Logs/CrashReporter/" stringByExpandingTildeInPath];        
            if (!UKValidateCrashLogFolder(crashLogsFolder)) {
                return;
            }
        }
    
			NSString*		crashLogName = [appName stringByAppendingString: @".crash.log"];
			NSString*		crashLogPath = nil;
			if( !isTenFiveOrBetter )
				crashLogPath = [crashLogsFolder stringByAppendingPathComponent: crashLogName];
			else
				crashLogPath = UKCrashReporterFindTenFiveCrashReportPath( appName, crashLogsFolder );
    
		NSDictionary*	fileAttrs = [[NSFileManager defaultManager] attributesOfItemAtPath:crashLogPath error:NULL];
			NSDate*			lastTimeCrashLogged = (fileAttrs == nil) ? nil : [fileAttrs fileModificationDate];
			NSTimeInterval	lastCrashReportInterval = [[NSUserDefaults standardUserDefaults] floatForKey: @"UKCrashReporterLastCrashReportDate"];
			NSDate*			lastTimeCrashReported = [NSDate dateWithTimeIntervalSince1970: lastCrashReportInterval];
			
			if( lastTimeCrashLogged )	// We have a crash log file and its mod date? Means we crashed sometime in the past.
			{
				// If we never before reported a crash or the last report lies before the last crash:
				if( [lastTimeCrashReported compare: lastTimeCrashLogged] == NSOrderedAscending )
				{
					// Fetch the newest report from the log:
					NSString*			crashLog = [NSString stringWithContentsOfFile: crashLogPath];
					NSArray*			separateReports = [crashLog componentsSeparatedByString: @"\n\n**********\n\n"];
					NSString*			currentReport = [separateReports count] > 0 ? [separateReports objectAtIndex: [separateReports count] -1] : @"*** Couldn't read Report ***";	// 1 since report 0 is empty (file has a delimiter at the top).
					unsigned			numCores = UKCountCores();
					NSString*			numCPUsString = (numCores == 1) ? @"" : [NSString stringWithFormat: @"%dx ",numCores];
					
					// Create a string containing Mac and CPU info, crash log and prefs:
					currentReport = [NSString stringWithFormat:
										@"Model: %@\nCPU Speed: %@%.2f GHz\n%@\n\nPreferences:\n%@",
										UKMachineName(), numCPUsString, ((float)UKClockSpeed()) / 1000.0f,
										currentReport,
										[[NSUserDefaults standardUserDefaults] persistentDomainForName: [[NSBundle mainBundle] bundleIdentifier]]];
					
					// Mugginsoft
					// append application log file
					if (appLogFilePath) {
						NSString *appLogText = [NSString stringWithContentsOfFile:appLogFilePath encoding:NSUTF8StringEncoding error:NULL];
						if (appLogText) {
							NSString *appendage = [NSString stringWithFormat:@"\n\nApplication Log: %@\n\n %@ \n\n", appLogFilePath, appLogText];
							currentReport = [currentReport stringByAppendingString:appendage];
						}
					}
					
					// Now show a crash reporter window so the user can edit the info to send:
					[[UKCrashReporter alloc] initWithLogString: currentReport];
				}
			}
		NS_HANDLER
			NSLog(@"Error during check for crash: %@",localException);
		NS_ENDHANDLER
	
	}
}

/*
 
 UKValidateCrashLogFolder
 
 */
BOOL UKValidateCrashLogFolder(NSString *crashLogsFolder)
{
    BOOL valid = YES;
    BOOL isDirectory = NO;
    
    // validate
    if ([[NSFileManager defaultManager] fileExistsAtPath:crashLogsFolder isDirectory:&isDirectory]) {
        if (!isDirectory) {
#ifdef UK_DEBUG
            NSLog(@"Diagnostic reports folder not found at : %@", crashLogsFolder);
#endif
            valid = NO;
        }
    }
    
    return valid;
}

NSString*	UKCrashReporterFindTenFiveCrashReportPath( NSString* appName, NSString* crashLogsFolder )
{
	NSDirectoryEnumerator*	enny = [[NSFileManager defaultManager] enumeratorAtPath: crashLogsFolder];
	NSString*				currName = nil;
	NSString*				crashLogPrefix = [NSString stringWithFormat: @"%@_",appName];
	NSString*				crashLogSuffix = @".crash";
	NSString*				foundName = nil;
	NSDate*					foundDate = nil;
	
	// Find the newest of our crash log files:
	while(( currName = [enny nextObject] ))
	{
		if( [currName hasPrefix: crashLogPrefix] && [currName hasSuffix: crashLogSuffix] )
		{
			NSDate*	currDate = [[enny fileAttributes] fileModificationDate];
			if( foundName )
			{
				if( [currDate isGreaterThan: foundDate] )
				{
					foundName = currName;
					foundDate = currDate;
				}
			}
			else
			{
				foundName = currName;
				foundDate = currDate;
			}
		}
	}
	
	if( !foundName )
		return nil;
	else
		return [crashLogsFolder stringByAppendingPathComponent: foundName];
}


NSString*	gCrashLogString = nil;


@implementation UKCrashReporter

-(id)	initWithLogString: (NSString*)theLog
{
	// In super init the awakeFromNib method gets called, so we can not
	//	use ivars to transfer the log, and use a global instead:
	gCrashLogString = theLog;
	
	self = [super init];
	return self;
}


-(id)	init
{
	self = [super init];
	if( self )
	{
		feedbackMode = YES;
	}
	return self;
}


-(void) dealloc
{
	connection = nil;
	
}


-(void)	awakeFromNib
{
	// Insert the app name into the explanation message:
	NSString*			appName = [[NSFileManager defaultManager] displayNameAtPath: [[NSBundle mainBundle] bundlePath]];
	NSMutableString*	expln = nil;
	if( gCrashLogString )
		expln = [[explanationField stringValue] mutableCopy];
	else
		expln = [NSLocalizedStringFromTable(@"FEEDBACK_EXPLANATION_TEXT",@"UKCrashReporter",@"") mutableCopy];
	[expln replaceOccurrencesOfString: @"%%APPNAME" withString: appName
				options: 0 range: NSMakeRange(0, [expln length])];
	[explanationField setStringValue: expln];
	
	// Insert user name and e-mail address into the information field:
	NSMutableString*	userMessage = nil;
	if( gCrashLogString )
		userMessage = [[informationField string] mutableCopy];
	else
		userMessage = [NSLocalizedStringFromTable(@"FEEDBACK_MESSAGE_TEXT",@"UKCrashReporter",@"") mutableCopy];
	[userMessage replaceOccurrencesOfString: @"%%LONGUSERNAME" withString: NSFullUserName()
				options: 0 range: NSMakeRange(0, [userMessage length])];
	ABMultiValue*	emailAddresses = [[[ABAddressBook sharedAddressBook] me] valueForProperty: kABEmailProperty];
	NSString*		emailAddr = NSLocalizedStringFromTable(@"MISSING_EMAIL_ADDRESS",@"UKCrashReporter",@"");
	if( emailAddresses )
	{
		NSString*		defaultKey = [emailAddresses primaryIdentifier];
		if( defaultKey )
		{
			NSUInteger	defaultIndex = [emailAddresses indexForIdentifier: defaultKey];
			if( defaultIndex != NSNotFound )
				emailAddr = [emailAddresses valueAtIndex: defaultIndex];
		}
	}
	[userMessage replaceOccurrencesOfString: @"%%EMAILADDRESS" withString: emailAddr
				options: 0 range: NSMakeRange(0, [userMessage length])];
	[informationField setString: userMessage];
	
	// Show the crash log to the user:
	if( gCrashLogString )
	{
		[crashLogField setString: gCrashLogString];
		//[gCrashLogString release];
		gCrashLogString = nil;
	}
	else
	{
		[remindButton setHidden: YES];
		
		NSInteger				itemIndex = [switchTabView indexOfTabViewItemWithIdentifier: @"de.zathras.ukcrashreporter.crashlog-tab"];
		NSTabViewItem*	crashLogItem = [switchTabView tabViewItemAtIndex: itemIndex];
		unsigned		numCores = UKCountCores();
		NSString*		numCPUsString = (numCores == 1) ? @"" : [NSString stringWithFormat: @"%dx ",numCores];
		[crashLogItem setLabel: NSLocalizedStringFromTable(@"SYSTEM_INFO_TAB_NAME",@"UKCrashReporter",@"")];
		
		NSString*	systemInfo = [NSString stringWithFormat: @"Application: %@ %@\nModel: %@\nCPU Speed: %@%.2f GHz\nSystem Version: %@\n\nPreferences:\n%@",
									appName, [[[NSBundle mainBundle] infoDictionary] objectForKey: @"CFBundleVersion"],
									UKMachineName(), numCPUsString, ((float)UKClockSpeed()) / 1000.0f,
									UKSystemVersionString(),
									[[NSUserDefaults standardUserDefaults] persistentDomainForName: [[NSBundle mainBundle] bundleIdentifier]]];
		[crashLogField setString: systemInfo];
	}
	
	// Show the window:
	[reportWindow makeKeyAndOrderFront: self];
}


-(IBAction)	sendCrashReport: (id)sender
{
	#pragma unused(sender)
	
	NSString            *boundary = @"0xKhTmLbOuNdArY";
	NSMutableString*	crashReportString = [NSMutableString string];
	[crashReportString appendString: [informationField string]];
	[crashReportString appendString: @"\n==========\n"];
	[crashReportString appendString: [crashLogField string]];
	[crashReportString replaceOccurrencesOfString: boundary withString: @"USED_TO_BE_KHTMLBOUNDARY" options: 0 range: NSMakeRange(0, [crashReportString length])];
	NSData*				crashReport = [crashReportString dataUsingEncoding: NSUTF8StringEncoding];
	
	// Prepare a request:
	NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL: [NSURL URLWithString: NSLocalizedStringFromTable( @"CRASH_REPORT_CGI_URL", @"UKCrashReporter", @"" )]];
	NSString            *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
	NSString			*agent = @"UKCrashReporter";
	
	// Add form trappings to crashReport:
	NSData*			header = [[NSString stringWithFormat:@"--%@\r\nContent-Disposition: form-data; name=\"crashlog\"\r\n\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding];
	NSMutableData*	formData = [header mutableCopy];
	[formData appendData: crashReport];
	[formData appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	// setting the headers:
	[postRequest setHTTPMethod: @"POST"];
	[postRequest setValue: contentType forHTTPHeaderField: @"Content-Type"];
	[postRequest setValue: agent forHTTPHeaderField: @"User-Agent"];
	NSString *contentLength = [NSString stringWithFormat:@"%lu", (long)[formData length]];
	[postRequest setValue: contentLength forHTTPHeaderField: @"Content-Length"];
	[postRequest setHTTPBody: formData];
	
	// Go into progress mode and kick off the HTTP post:
	[progressIndicator startAnimation: self];
	[sendButton setEnabled: NO];
	[remindButton setEnabled: NO];
	[discardButton setEnabled: NO];
	
	connection = [NSURLConnection connectionWithRequest: postRequest delegate: self];
}


-(IBAction)	remindMeLater: (id)sender
{
	#pragma unused(sender)
	
	[reportWindow orderOut: self];
}


-(IBAction)	discardCrashReport: (id)sender
{
	#pragma unused(sender)
	
	// Remember we already did this crash, so we don't ask twice:
	if( !feedbackMode )
	{
		[[NSUserDefaults standardUserDefaults] setFloat: (float)[[NSDate date] timeIntervalSince1970] forKey: @"UKCrashReporterLastCrashReportDate"];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}

	[reportWindow orderOut: self];
}


-(void)	showFinishedMessage: (NSError*)errMsg
{
	if( errMsg )
	{
		NSString*		errTitle = nil;
		if( feedbackMode )
			errTitle = NSLocalizedStringFromTable( @"COULDNT_SEND_FEEDBACK_ERROR",@"UKCrashReporter",@"");
		else
			errTitle = NSLocalizedStringFromTable( @"COULDNT_SEND_CRASH_REPORT_ERROR",@"UKCrashReporter",@"");
		
		NSRunAlertPanel( errTitle, @"%@", NSLocalizedStringFromTable( @"COULDNT_SEND_CRASH_REPORT_ERROR_OK",@"UKCrashReporter",@""), @"", @"",
						 [errMsg localizedDescription] );
	}
	
	[reportWindow orderOut: self];
	//[self autorelease];
}


-(void)	connectionDidFinishLoading:(NSURLConnection *)conn
{
	#pragma unused(conn)
	
	connection = nil;
	
	// Now that we successfully sent this crash, don't report it again:
	if( !feedbackMode )
	{
		[[NSUserDefaults standardUserDefaults] setFloat: (float)[[NSDate date] timeIntervalSince1970] forKey: @"UKCrashReporterLastCrashReportDate"];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
	
	[self performSelectorOnMainThread: @selector(showFinishedMessage:) withObject: nil waitUntilDone: NO];
}


-(void)	connection:(NSURLConnection *)conn didFailWithError:(NSError *)error
{
	#pragma unused(conn)
	
	connection = nil;
	
	[self performSelectorOnMainThread: @selector(showFinishedMessage:) withObject: error waitUntilDone: NO];
}

@end


@implementation UKFeedbackProvider

-(IBAction) orderFrontFeedbackWindow: (id)sender
{
	#pragma unused(sender)
	
	[[UKCrashReporter alloc] init];
}


-(IBAction) orderFrontBugReportWindow: (id)sender
{
	#pragma unused(sender)
	
	[[UKCrashReporter alloc] init];
}

@end
