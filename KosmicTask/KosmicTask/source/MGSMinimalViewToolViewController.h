//
//  MGSMinimalViewToolViewController.h
//  Mother
//
//  Created by Jonathan on 21/09/2009.
//  Copyright 2009 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSToolViewController.h"

@interface MGSMinimalViewToolViewController : MGSToolViewController {
	IBOutlet NSSegmentedControl *segmentedButtons;
}

- (IBAction)segControlClicked:(id)sender;
- (void)segmentClick:(int)selectedSegment;
- (void)initialiseForWindow:(NSWindow *)window;


@end
