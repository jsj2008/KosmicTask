//
//  MGSListParameterInputViewController.h
//  Mother
//
//  Created by Jonathan on 08/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSParameterSubInputViewController.h"

@interface MGSListParameterInputViewController : MGSParameterSubInputViewController {
	NSArrayController *_arrayController;
	NSString *_defaultValue;
	
	IBOutlet NSTableView *_tableView;
}

@end
