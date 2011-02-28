//
//  MGSNumberInputViewController.h
//  Mother
//
//  Created by Jonathan on 06/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSViewController.h"

typedef enum _MGSNumberInputViewNotation {
	kMGSNumberInputViewDecimalNotation = 0,
	kMGSNumberInputViewScientificENotation = 1,
	kMGSNumberInputViewCurrencyNotation = 2,
	kMGSNumberInputViewPercentNotation = 3,
} MGSNumberInputViewNotation;


@interface MGSNumberInputViewController : NSViewController {
	IBOutlet NSTextField *textField;
	IBOutlet NSStepper *stepper;
	
	double _value;
	double _increment;
	double _minValue;
	double _maxValue;
	NSInteger _decimalPlaces;
	MGSNumberInputViewNotation _notation;
	
	BOOL _updateObservedObject;
	NSMutableDictionary *_bindings;
}


@property double value;
@property double increment;
@property double minValue;
@property double maxValue;
@property NSTextField *textField;
@property NSStepper *stepper;
@property MGSNumberInputViewNotation notation;
@property NSInteger decimalPlaces;

- (NSNumber *)numberValue;
- (void)setNumberValue:(NSNumber *)number;
- (NSNumberFormatter *)formatter;
- (NSNumber *)formattedNumberValue;
@end
