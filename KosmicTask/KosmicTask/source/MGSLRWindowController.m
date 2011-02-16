//
//  MGSLRWindowController.m
//  KosmicTask
//
//  Created by Jonathan on 05/02/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSLRWindowController.h"
#import "MGSLM.h"
#import "MGSLWindowController.h"
#import "MGSAppTrial.h"

static BOOL trialExpired = NO;

@implementation MGSLRWindowController

#pragma mark -
#pragma mark Instance handling

/*
 
 init
 
 */
- (id)init
{
	if ((self = [super initWithWindowNibName:@"LicenceReminder"])) {
	}

	return self;
}

/*
 
 function awakeFromNib
 
 */
- (void)awakeFromNib
{
	NSString *title, *message;
	NSUInteger trialDaysRemaining = 0;
	NSUInteger trialDays = 0;
	
	
	// check for trial expiry
	trialExpired = MGSAppTrialPeriodExpired(&trialDaysRemaining);
	
	// configure accordingly
	if (trialExpired) {
		title = NSLocalizedString(@"%i Day Trial Licence Expired", @"dialog text");
		message = NSLocalizedString(@"Sorry, this %i day trial version of KosmicTask has expired. To continue using this software please buy and install a licence.", @"dialog text");
		[titleTextField setTextColor:[NSColor redColor]];
		trialDays = MGS_APP_TRIAL_DAYS;
	} else {
		title = NSLocalizedString(@"%i Day Free Trial", @"dialog text");
		message = NSLocalizedString(@"This trial version of KosmicTask is fully functional but will stop working after %i days unless a full licence is installed.", @"dialog text");
		trialDays = trialDaysRemaining;
	}

	// remaining days
	NSString *remainingDays =  NSLocalizedString(@"%i trial days remaining", @"dialog text");
	if (trialDaysRemaining == 1) {
		remainingDays =  NSLocalizedString(@"%i trial day remaining", @"dialog text");
	}
	
	[titleTextField setStringValue:[NSString stringWithFormat:title, MGS_APP_TRIAL_DAYS]];
	[messageTextField setStringValue:[NSString stringWithFormat:message, MGS_APP_TRIAL_DAYS]];
	[remainingDaysTextField  setStringValue:[NSString stringWithFormat:remainingDays, trialDaysRemaining]];
}


#pragma mark -
#pragma mark Actions

/*
 
 function closeWindow:(id)sender
 
 */
 -(IBAction)closeWindow:(id)sender
{
	#pragma unused(sender)

	// close the window
	[self close];
	
	// terminate if trial expired
	if (trialExpired) {
		[NSApp terminate:self];
	}
}

/*
 
 close
 
 */
- (void)close
{
	// stop modal
	[NSApp stopModalWithCode:trialExpired == YES ? MGS_APP_TRIAL_EXPIRED : MGS_APP_TRIAL_VALID];
	
	// super implements the close
	[super close];
}

/*
 
 function openBuyURL:(id)sender
 
 */
-(IBAction)openBuyURL:(id)sender
{
	#pragma unused(sender)
		
	// buy licences
	[MGSLM buyLicences];
}

/*
 
 function installLicence:(id)sender
 
 */
-(IBAction)installLicence:(id)sender
{
	#pragma unused(sender)
	
	// close the window
	[self close];
	
	// install licence
	if (trialExpired) {
		
		// show the licence window now otherwise our app will terminate
		// when now window displayed
		[[MGSLWindowController sharedController] showWindow:self];
	} else {
		
		// delay show
		[[MGSLWindowController sharedController] performSelector:@selector(showWindow:) withObject:self afterDelay:4];
	}
}
@end
