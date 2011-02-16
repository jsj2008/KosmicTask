//
//  MGSNumberParameterInputViewController.h
//  Mother
//
//  Created by Jonathan on 07/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSParameterSubInputViewController.h"

@class MGSNumberInputViewController;

@interface MGSNumberParameterInputViewController : MGSParameterSubInputViewController {
	IBOutlet NSView *valueInputView;
	IBOutlet NSTextField *_minValueTextField;
	IBOutlet NSTextField *_maxValueTextField;
	IBOutlet NSSlider *_valueSlider;
	
	MGSNumberInputViewController *_numberInputViewController;
	
	BOOL _wholeNumber;
	double _minValue;
	double _maxValue;
	double _incrementValue;	
}


@property double minValue;
@property double maxValue;
@property BOOL wholeNumber;
@property double incrementValue;

@end
