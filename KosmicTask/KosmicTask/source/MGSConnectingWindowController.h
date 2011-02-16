//
//  MGSConnectingWindowController.h
//  Mother
//
//  Created by Jonathan on 27/04/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MGSConnectingWindowController : NSWindowController {
	IBOutlet NSProgressIndicator *progressIndicator;
	IBOutlet NSTextField *versionTextField;
	NSString *_version;
	NSString *_licensedTo;
}

@property (assign) NSString *version;
@property (assign) NSString *licensedTo;

- (void)hideWindow:(id)sender;
- (NSString *)version;

@end
