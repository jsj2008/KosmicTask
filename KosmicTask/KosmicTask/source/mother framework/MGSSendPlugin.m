//
//  MGSSendPlugin.m
//  Mother
//
//  Created by Jonathan on 21/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSSendPlugin.h"
#import "MGSError.h"

static NSOperationQueue *_operationQueue = nil;

@interface MGSSendPlugin()
- (NSOperationQueue *)operationQueue;
@end

@implementation MGSSendPlugin


/*
 
 target app name
 
 */
- (NSString *)targetAppName
{
	return @"Unknown.app";
}

/*
 
 bundle identifier
 
 */
- (NSString *)bundleIdentifier
{
	return @"unknown.unknown.unknown.unknown";
}

/*
 
 on exception
 
 */
- (void)onException:(NSException *)e
{
	NSString *error = [NSString stringWithFormat: NSLocalizedString(@"Data could not be sent to: %@ : %@", @"Send plugin error string"), [self targetAppName], [e description]];
	[MGSError clientCode:MGSErrorCodeSendPlugin reason:error];
}

/*
 
 target app installed
 
 */
- (BOOL)targetAppInstalled
{
	if (![[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:[self bundleIdentifier]]) {
		return NO;
	}
	
	return YES;
}

/*
 
 copy object to pasteboard as RTF
 
 */
- (void)copyToPasteboardAsRTF:(id)object
{
	NSAttributedString *aString = nil;
	
	if ([object isKindOfClass:[NSAttributedString class]]) {
		aString = object;
	} else {
		aString = [[NSAttributedString alloc] initWithString:[object description]];
	}
	
	// prepare the pasteboard
	NSPasteboard *pb = [NSPasteboard generalPasteboard];
	NSArray *types = [NSArray arrayWithObjects: NSStringPboardType, NSRTFPboardType, nil];
	[pb declareTypes:types owner:self];
	
	// add string representation
	[pb setString:[aString string] forType:NSStringPboardType];
	
	// add the RTF representation
	NSData *rtfData = [aString
					   RTFFromRange:(NSMakeRange(0, [aString length]))
					   documentAttributes:nil];
	[pb setData:rtfData forType:NSRTFPboardType];
	
}

/*
 
 send string
 
 sending data to external applications can block the app.
 hence, copy the string and execute via NSOperationQueue
 */
- (BOOL)sendAttributedString:(NSAttributedString *)aString
{
	return [self queueSelector:@selector(executeSend:) withObject:[aString copy]];
}

/*
 
 execute script
 
 */
- (BOOL)executeAppleScript:(NSString *)script
{
	BOOL success = NO;
	
	NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:script];
	NSDictionary *errorInfo = nil;
	if (![appleScript executeAndReturnError:&errorInfo]) {
		NSLog(@"AppleScript execution error: %@", errorInfo);
		success = NO;
	} else {
		success =  YES;
	}
	
	return success;
}

/*
 
 queue selector
 
 */
- (BOOL)queueSelector:(SEL)selector withObject:(id)object
{
	BOOL success = NO;
	
	NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self
																		selector:selector object:object];
	if (theOp) {
		[[self operationQueue] addOperation:theOp];
		success = YES;
	}
	return success;
}
/*
 
 execute send
 
 subclass must override
 
 will be executed in a separate thread via NSOperationQueue
 
 */
- (BOOL)executeSend:(NSAttributedString *)aString
{
	#pragma unused(aString)
	
	return NO;
}
/*
 
 operation queue
 
 */
- (NSOperationQueue *)operationQueue
{
	// lazy allocation
	if (!_operationQueue) {
		_operationQueue = [[NSOperationQueue alloc] init];
	}
	
	return _operationQueue;
}
 
@end
