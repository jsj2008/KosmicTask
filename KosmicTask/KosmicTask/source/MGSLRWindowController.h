//
//  MGSLRWindowController.h
//  KosmicTask
//
//  Created by Jonathan on 05/02/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MGSLRWindowController : NSWindowController {
	IBOutlet NSTextField *titleTextField;
	IBOutlet NSTextField *messageTextField;
	IBOutlet NSTextField *remainingDaysTextField;
}

// actions
-(IBAction)closeWindow:(id)sender;
-(IBAction)openBuyURL:(id)sender;
-(IBAction)installLicence:(id)sender;

@end
