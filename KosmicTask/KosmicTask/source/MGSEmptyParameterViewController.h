//
//  MGSEmptyParameterViewController.h
//  Mother
//
//  Created by Jonathan on 27/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MGSEmptyParameterViewController : NSViewController {
	IBOutlet NSView *centreView;
	IBOutlet NSTextField *_textField;
}

- (void)viewDidResize:(NSNotification *)note;

@end
