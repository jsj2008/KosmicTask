//
//  MGSDateParameterEditViewController.h
//  Mother
//
//  Created by Jonathan on 06/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSParameterSubEditViewController.h"

@interface MGSDateParameterEditViewController : MGSParameterSubEditViewController {
	IBOutlet NSButton *currentDateCheckBox;
	IBOutlet NSDatePicker *textualDatePicker;
	IBOutlet NSDatePicker *graphicalDatePicker;	
	
	NSDate *_initialDate;
	BOOL _initialiseToCurrentDate;
	BOOL _enableDatePickers;
}

@property (copy) NSDate *initialDate;
@property (nonatomic) BOOL initialiseToCurrentDate;
@property BOOL enableDatePickers;
@end
