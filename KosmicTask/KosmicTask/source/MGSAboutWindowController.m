//
//  MGSAboutWindowController.m
//  Mother
//
//  Created by Jonathan on 24/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSAboutWindowController.h"
#import "MGSAppController.h"
#import "MGSLM.h"
#import "MGSTask.h"
#import "MGSCodeSigning.h"
#import "MGSMotherServerLocalController.h"
#import "NSBundle_Mugginsoft.h"
#import "MGSPath.h"

@implementation MGSAboutWindowController

@synthesize version = _version;
@synthesize build = _build;
@synthesize credits = _credits;
@synthesize licensedTo = _licensedTo;
@synthesize appCodeSignatureStatus = _appCodeSignatureStatus;
@synthesize serverCodeSignatureStatus = _serverCodeSignatureStatus;
@synthesize taskCodeSignatureStatus = _taskCodeSignatureStatus;
/*
 
 shared instance
 
 */
+ (MGSAboutWindowController *) sharedInstance
{
    static MGSAboutWindowController	*sharedInstance = nil;
	
    if (sharedInstance == nil)
    {
        sharedInstance = [[self alloc] init];
		[sharedInstance initWithWindowNibName:@"AboutWindow"];
    }
	
    return sharedInstance;
}


/*
 
 window did load
 
 */
- (void)windowDidLoad
{
	// credits
    //	Locate the README.rtf inside the application’s bundle.
    NSString *path = [[NSBundle mainBundle] pathForResource: @"Credits" ofType: @"rtf"];
	self.credits =  path ?[[NSMutableAttributedString alloc] initWithPath: path documentAttributes: NULL] : @"";
	
	// version
	MGSAppController *appController = [NSApp delegate];
	self.version =  [appController versionStringForDisplay];
	self.build =  [appController buildStringForDisplay];
	
	// validate application code siging
	MGSCodeSigning *codeSign = [MGSCodeSigning new];
	[codeSign validateApplication];
	self.appCodeSignatureStatus = [NSString stringWithFormat: NSLocalizedString(@"Application code signature: %@", @"About window code signature text"), 
								codeSign.resultString];

	// validate server code siging
	[codeSign validatePath:[MGSPath bundlePathForHelperExecutable:MGSKosmicTaskAgentName]];
	self.serverCodeSignatureStatus = [NSString stringWithFormat: NSLocalizedString(@"Server code signature: %@", @"About window code signature text"), 
								codeSign.resultString];

}

/*
 
 show window override
 
 */
- (IBAction)showWindow:(id)sender
{
	// licencee
	self.licensedTo = [NSString stringWithFormat: NSLocalizedString(@"Licensed to: %@", @"About window licencee text"), 
					   [[MGSLM sharedController] firstOwner]];
	
	[super showWindow:sender];
}
@end
