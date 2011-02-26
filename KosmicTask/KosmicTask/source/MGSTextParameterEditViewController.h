//
//  MGSTextParameterEditViewController.h
//  Mother
//
//  Created by Jonathan on 06/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSParameterSubEditViewController.h"
#import "MGSTextParameterPlugin.h"

@interface MGSTextParameterEditViewController : MGSParameterSubEditViewController {
	IBOutlet NSTextView *textView;
	IBOutlet NSButton *allowEmptyInputCheckbox;
	NSString *_defaultText;
	BOOL _allowEmptyInput;
	IBOutlet NSPopUpButton *initialInputSizePopUpButton;
	MGSTextParameterInputStyle inputStyle;
}

@property (copy) NSString *defaultText;
@property BOOL allowEmptyInput;
@property MGSTextParameterInputStyle inputStyle;

@end
