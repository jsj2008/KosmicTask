//
//  MGSWaitViewController.h
//  Mother
//
//  Created by Jonathan on 12/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MGSWaitViewController : NSViewController {
	IBOutlet NSTextField *text;
	IBOutlet NSProgressIndicator *progress;
}

- (void)clear;

@end
