//
//  MGSListParameterEditViewController.h
//  Mother
//
//  Created by Jonathan on 08/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSParameterSubEditViewController.h"

@class MGSListParameterItem;
@class MGSArrayController;

@interface MGSListParameterEditViewController : MGSParameterSubEditViewController {
	NSArrayController *_arrayController;
	
	IBOutlet NSTableView *_tableView;
	IBOutlet NSSegmentedControl *_segmentedControl;

}

- (IBAction)segmentClick:(id)sender;
- (void)setIsInitialValue:(BOOL)isInitial forItem:(MGSListParameterItem *)item;
@end
