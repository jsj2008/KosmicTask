//
//  MGSViewController.h
//  Mother
//
//  Created by Jonathan on 27/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class NSViewController;

@protocol MGSViewController

@optional
- (void)viewDidLoad:(NSView *)view;
- (id)initWithDelegate:(id)delegate;
@end

@interface MGSViewController : NSViewController {
	id _delegate;
}


@property id delegate;

@end
