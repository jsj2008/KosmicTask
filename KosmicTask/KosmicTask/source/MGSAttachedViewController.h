//
//  MGSAttachedViewController.h
//  Mother
//
//  Created by Jonathan on 26/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MGSAttachedViewController : NSViewController {
    IBOutlet NSTextField *textField;
	NSString *_text;
	NSColor *_textColor;
}

@property (copy, nonatomic) NSString *text;
@property (strong) NSColor *textColor;
@end
