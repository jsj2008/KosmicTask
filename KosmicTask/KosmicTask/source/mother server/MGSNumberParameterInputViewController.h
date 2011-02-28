//
//  MGSNumberParameterInputViewController.h
//  Mother
//
//  Created by Jonathan on 07/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSParameterSubInputViewController.h"

#import "MGSNumberInputViewController.h"

@interface MGSNumberParameterInputViewController : MGSParameterSubInputViewController {
	IBOutlet NSView *valueInputView;
	IBOutlet NSTextField *_minValueTextField;
	IBOutlet NSTextField *_maxValueTextField;
	IBOutlet NSSlider *_valueSlider;
	
	MGSNumberInputViewController *_numberInputViewController;
	
	double _minValue;
	double _maxValue;
	double _incrementValue;	
	MGSNumberInputViewNotation _notation;
	NSInteger _decimalPlaces;
	double _sliderValue;
	BOOL _updateSliderValue;
}


@property double minValue;
@property double maxValue;
@property double incrementValue;
@property MGSNumberInputViewNotation notation;
@property NSInteger decimalPlaces;
@property double sliderValue;
@end
