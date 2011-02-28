//
//  MGSNumberParameterEditViewController.h
//  Mother
//
//  Created by Jonathan on 06/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSParameterSubEditViewController.h"
#import "MGSNumberInputViewController.h"

@class MGSNumberInputViewController;

@interface MGSNumberParameterEditViewController : MGSParameterSubEditViewController {
	IBOutlet NSPopUpButton *stylePopupButton;
	IBOutlet NSPopUpButton *decimalPlacesPopupButton;
	IBOutlet NSView *initialValueInputView;
	IBOutlet NSView *minValueInputView;
	IBOutlet NSView *maxValueInputView;
	IBOutlet NSView *incrementValueInputView;
	
	MGSNumberInputViewNotation _notation;
	
	MGSNumberInputViewController *_initialValueInput;
	MGSNumberInputViewController *_minValueInput;
	MGSNumberInputViewController *_maxValueInput;
	MGSNumberInputViewController *_incrementValueInput;
	
	double _initialValue;
	double _minValue;
	double _maxValue;
	double _incrementValue;	
	double _representationMax;
	double _representationMin;
	double _minIncrement;
	double _maxIncrement;
	NSInteger _decimalPlaces;
}

@property double initialValue;
@property double minValue;
@property double maxValue;
@property double incrementValue;	
@property double representationMax;
@property double representationMin;
@property double minIncrement;
@property double maxIncrement;
@property MGSNumberInputViewNotation notation;
@property NSInteger decimalPlaces;

@end
