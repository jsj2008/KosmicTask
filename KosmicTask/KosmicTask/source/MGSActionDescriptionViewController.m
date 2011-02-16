//
//  MGSActionDescriptionViewController.m
//  Mother
//
//  Created by Jonathan on 30/07/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSActionDescriptionViewController.h"
#import "MGSScript.h"
#import "MGSTaskSpecifier.h"
#import "NSTextField_Mugginsoft.h"

@implementation MGSActionDescriptionViewController

@synthesize actionSpecifier = _actionSpecifier;

/*
 
 init
 
 */
-(id)init 
{
	if ([super initWithNibName:@"ActionDescriptionView" bundle:nil]) {
		
	}
	return self;
}

/*
 
 awake from nib
 
 */
- (void)awakeFromNib
{
	[_scrollView setBorderType:NSNoBorder];
	
	// text view defaults to NSConditionallySetsEditableBindingOption == YES
	[_description bind:NSDataBinding toObject:self withKeyPath:@"actionSpecifier.script.longDescription" 
			   options:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], NSConditionallySetsEditableBindingOption, nil]];
}


@end
