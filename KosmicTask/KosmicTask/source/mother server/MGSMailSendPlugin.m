//
//  MGSMailSendPlugin.m
//  Mother
//
//  Created by Jonathan on 22/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
// see the SBSendMail Apple example code project
// http://developer.apple.com/samplecode/SBSendEmail/index.html
//
// also:
// http://developer.apple.com/samplecode/ScriptingAutomation/idxScriptingBridges-date.html
// http://developer.apple.com/samplecode/ScriptingBridgeFinder/index.html
//
#import "MGSMailSendPlugin.h"
#import "Mail.h"	// this is created dynamically by target build rule. Use file - open quickly... <name>.h to view.

@implementation MGSMailSendPlugin


/*
 
 target app name
 
 */
- (NSString *)targetAppName
{
	return @"Mail.app";
}

/*
 
 bundle identifier
 
 */
- (NSString *)bundleIdentifier
{
	return @"com.apple.Mail";
}

/*
 
 send string
 
 will be executed in a separate thread via NSOperationQueue
 
 */
- (BOOL)executeSend:(NSAttributedString *)aString
{
	BOOL success = NO;
	
	@try {
		/* create a Scripting Bridge object for talking to the Mail application */
		MailApplication *mail = [SBApplication applicationWithBundleIdentifier:[self bundleIdentifier]];

		
		/* create a new outgoing message object */
		MailOutgoingMessage *emailMessage =
		[[[mail classForScriptingClass:@"outgoing message"] alloc] initWithProperties:
		 [NSDictionary dictionaryWithObjectsAndKeys: @"", @"subject",
													[aString string], @"content", nil]];
		
		/* add the object to the mail app  */
		[[mail outgoingMessages] addObject: emailMessage];
		
		/* set the sender, show the message */
		//emailMessage.sender = [self.fromField stringValue];
		[mail activate];
		emailMessage.visible = YES;
		
		/* create a new recipient and add it to the recipients list */
		/*
		 MailToRecipient *theRecipient =
		[[[mail classForScriptingClass:@"to recipient"] alloc]
		 initWithProperties:
		 [NSDictionary dictionaryWithObjectsAndKeys:
		  [self.toField stringValue], @"address",
		  nil]];
		[emailMessage.toRecipients addObject: theRecipient];
		*/
		
		/* add an attachment, if one was specified */
		/*
		NSString *attachmentFilePath = [self.fileAttachmentField stringValue];
		if ( [attachmentFilePath length] > 0 ) {
			
			// create an attachment object
			MailAttachment *theAttachment = [[[mail
											   classForScriptingClass:@"attachment"] alloc]
											 initWithProperties:
											 [NSDictionary dictionaryWithObjectsAndKeys:
											  attachmentFilePath, @"fileName",
											  nil]];
			
			// add it to the list of attachments
			[[emailMessage.content attachments] addObject: theAttachment];
		}
		*/

		/* send the message */
		//[emailMessage send];
		
		success =  YES;
	} @catch (NSException *e) {
		[self onException:e];
	}
	
	return success;
}

/* 
 
 menu item string
 
 */
- (NSString *)menuItemString
{
	return NSLocalizedString(@"Mail", @"Send plugin menu item string");
}
@end
