//
//  MGSActionOptionsViewController.m
//  Mother
//
//  Created by Jonathan on 30/07/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSActionOptionsViewController.h"
#import "MGSScript.h"
#import "MGSTaskSpecifier.h"
#import "NSTextField_Mugginsoft.h"
#import "MGSNetRequest.h"

@implementation MGSActionOptionsViewController

@synthesize actionSpecifier = _actionSpecifier;
@synthesize useTimeout = _useTimeout;

/*
 
 init
 
 */
-(id)init 
{
	if ([super initWithNibName:@"ActionOptionsView" bundle:nil]) {
		_useTimeout = NO;
	}
	return self;
}

/*
 
 awake from nib
 
 */
- (void)awakeFromNib
{
	
	[_timeout bind:NSValueBinding toObject:self withKeyPath:@"actionSpecifier.script.timeout" options:nil];
	[_timeoutStepper bind:NSValueBinding toObject:self withKeyPath:@"actionSpecifier.script.timeout" 
				  options:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], NSConditionallySetsEnabledBindingOption, nil]];
	[_useTimeoutButton bind:NSValueBinding toObject:self withKeyPath:@"useTimeout" options:nil]; 
}

/*
 
 set action
 
 */
- (void)setActionSpecifier:(MGSTaskSpecifier *)action
{
	_actionSpecifier = action;
	MGSScript *script = [action script];

	// options
	self.useTimeout = [script timeout] > 0 ? YES : NO;
}

/*
 
 set use timeout
 
 */
- (void)setUseTimeout:(BOOL)value
{
	_useTimeout = value;
	[_timeout setEnabled:value];
	[_timeoutStepper setEnabled:value];
	
	float myTimeout;
	if (_useTimeout) {
		myTimeout = MGS_STANDARD_TIMEOUT;
	} else {
		myTimeout = 0.0f;
	}
	[_actionSpecifier setValue:[NSNumber numberWithFloat:myTimeout] forKeyPath:@"script.timeout"];
}

@end
