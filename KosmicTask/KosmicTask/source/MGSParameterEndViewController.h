//
//  MGSParameterEndView.h
//  Mother
//
//  Created by Jonathan on 12/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MGSPopupButton;

@interface MGSParameterEndViewController : NSViewController {
	IBOutlet NSTextField *_textField;
    IBOutlet NSSegmentedControl *inputSegmentedControl;
    IBOutlet MGSPopupButton *contextPopupButton;
}

@property (readonly) NSSegmentedControl *inputSegmentedControl;
@property (readonly) MGSPopupButton *contextPopupButton;

@end
