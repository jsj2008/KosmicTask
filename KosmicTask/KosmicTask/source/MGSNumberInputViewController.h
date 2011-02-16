//
//  MGSNumberInputViewController.h
//  Mother
//
//  Created by Jonathan on 06/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSViewController.h"

@interface MGSNumberInputViewController : NSViewController {
	IBOutlet NSTextField *textField;
	IBOutlet NSStepper *stepper;
	
	double _value;
	double _increment;
	double _minValue;
	double _maxValue;
	BOOL _integralValue;
	
	BOOL _updateObservedObject;
	NSMutableDictionary *_bindings;
}


@property double value;
@property double increment;
@property double minValue;
@property double maxValue;
@property NSTextField *textField;
@property NSStepper *stepper;
@property BOOL integralValue;

- (NSNumber *)numberValue;
- (void)setNumberValue:(NSNumber *)number;
@end
