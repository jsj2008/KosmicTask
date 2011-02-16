//
//  MGSNumberParameterEditViewController.h
//  Mother
//
//  Created by Jonathan on 06/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSParameterSubEditViewController.h"

@class MGSNumberInputViewController;

@interface MGSNumberParameterEditViewController : MGSParameterSubEditViewController {
	IBOutlet NSButton *wholeNumberCheckbox;
	IBOutlet NSView *initialValueInputView;
	IBOutlet NSView *minValueInputView;
	IBOutlet NSView *maxValueInputView;
	IBOutlet NSView *incrementValueInputView;
	
	BOOL _wholeNumber;

	MGSNumberInputViewController *_initialValueInput;
	MGSNumberInputViewController *_minValueInput;
	MGSNumberInputViewController *_maxValueInput;
	MGSNumberInputViewController *_incrementValueInput;
	
	double _initialValue;
	double _minValue;
	double _maxValue;
	double _incrementValue;	
}

@property BOOL wholeNumber;
@property double initialValue;
@property double minValue;
@property double maxValue;
@property double incrementValue;	

@end
