//
//  MGSDateParameterInputViewController.h
//  Mother
//
//  Created by Jonathan on 07/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSParameterSubInputViewController.h"

@interface MGSDateParameterInputViewController : MGSParameterSubInputViewController {
	IBOutlet NSDatePicker *textualDatePicker;
	IBOutlet NSDatePicker *graphicalDatePicker;	
	BOOL _initialiseToCurrentDate;
}

@end
