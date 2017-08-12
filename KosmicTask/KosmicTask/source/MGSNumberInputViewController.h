//
//  MGSNumberInputViewController.h
//  Mother
//
//  Created by Jonathan on 06/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSViewController.h"

enum _MGSNumberInputViewNotation {
	kMGSNumberInputViewDecimalNotation = 0,
	kMGSNumberInputViewScientificENotation = 1,
	kMGSNumberInputViewCurrencyNotation = 2,
	kMGSNumberInputViewPercentNotation = 3,
};
typedef NSInteger MGSNumberInputViewNotation;


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


@property (nonatomic) double value;
@property (nonatomic) double increment;
@property (nonatomic) double minValue;
@property (nonatomic) double maxValue;
@property NSTextField *textField;
@property NSStepper *stepper;
@property (nonatomic) MGSNumberInputViewNotation notation;
@property (nonatomic) NSInteger decimalPlaces;

- (NSNumber *)numberValue;
- (void)setNumberValue:(NSNumber *)number;
- (NSNumberFormatter *)formatter;
- (NSNumber *)formattedNumberValue;
@end
