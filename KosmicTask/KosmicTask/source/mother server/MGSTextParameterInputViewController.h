//
//  MGSTextParameterInputViewController.h
//  Mother
//
//  Created by Jonathan on 07/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSParameterSubInputViewController.h"

@interface MGSTextParameterInputViewController : MGSParameterSubInputViewController {
	IBOutlet NSTextView *textView;
	BOOL _allowEmptyInput;
}

@property BOOL allowEmptyInput;

@end
