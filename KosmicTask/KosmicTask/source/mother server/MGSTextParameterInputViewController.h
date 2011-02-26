//
//  MGSTextParameterInputViewController.h
//  Mother
//
//  Created by Jonathan on 07/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSParameterSubInputViewController.h"
#import "MGSTextParameterPlugin.h"

@interface MGSTextParameterInputViewController : MGSParameterSubInputViewController {
	IBOutlet NSTextView *textView;
	IBOutlet NSTextField *textField;
	BOOL _allowEmptyInput;
	MGSTextParameterInputStyle inputStyle;
	IBOutlet NSView *singleLineView;
	IBOutlet NSView *multiLineView;
}

@property BOOL allowEmptyInput;
@property MGSTextParameterInputStyle inputStyle;

@end
