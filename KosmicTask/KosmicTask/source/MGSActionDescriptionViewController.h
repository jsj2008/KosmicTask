//
//  MGSActionDescriptionViewController.h
//  Mother
//
//  Created by Jonathan on 30/07/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MGSTaskSpecifier;

@interface MGSActionDescriptionViewController : NSViewController {
	MGSTaskSpecifier *__weak _actionSpecifier;
	
	IBOutlet NSTextView *_description;
	IBOutlet NSScrollView *_scrollView;
}


@property (weak) MGSTaskSpecifier *actionSpecifier;

@end
