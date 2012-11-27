//
//  MGSResultToolViewController.h
//  Mother
//
//  Created by Jonathan on 27/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSToolViewController.h"

@class MGSPopupButton;

@interface MGSResultToolViewController : MGSToolViewController {
	IBOutlet NSSegmentedControl *segmentedButtons;
	IBOutlet MGSPopupButton *actionPopupButton;
}

@property (readonly) MGSPopupButton *actionPopupButton;

- (IBAction)segControlClicked:(id)sender;
- (void)segmentClick:(NSInteger)selectedSegment;
- (void)initialiseForWindow:(NSWindow *)window;

@end
