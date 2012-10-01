//
//  MGSRemoveServerWindowController.h
//  Mother
//
//  Created by Jonathan on 06/04/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MGSRemoveServerWindowController : NSWindowController {
	IBOutlet NSArrayController *arrayController;
	IBOutlet NSButton *disconnectButton;
	
	id _delegate;
}

- (void)closeWindow;
- (IBAction)cancel:(id)sender;
- (IBAction)disconnect:(id)sender;

@property id delegate;
@end
