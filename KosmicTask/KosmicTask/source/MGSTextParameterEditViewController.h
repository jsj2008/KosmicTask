//
//  MGSTextParameterEditViewController.h
//  Mother
//
//  Created by Jonathan on 06/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSParameterSubEditViewController.h"

@interface MGSTextParameterEditViewController : MGSParameterSubEditViewController {
	IBOutlet NSTextView *textView;
	IBOutlet NSButton *allowEmptyInputCheckbox;
	NSString *_defaultText;
	BOOL _allowEmptyInput;
}

@property (copy) NSString *defaultText;
@property BOOL allowEmptyInput;

@end
