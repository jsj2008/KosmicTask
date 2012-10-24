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
#import "MGSPreferences.h"

@implementation MGSActionOptionsViewController

@synthesize actionSpecifier = _actionSpecifier;
@synthesize useTimeout = _useTimeout;
@synthesize timeout = _timeout;
@synthesize timeoutUnits = _timeoutUnits;

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
	_scriptController = [[NSObjectController alloc] init];
    
    // timeout settings
	[_timeoutField bind:NSValueBinding toObject:_scriptController withKeyPath:@"selection.timeout" options:nil];
    [_timeoutField bind:NSEnabledBinding toObject:_scriptController withKeyPath:@"selection.applyTimeout" options:nil];
    
	[_timeoutStepper bind:NSValueBinding toObject:_scriptController withKeyPath:@"selection.timeout" 
				  options:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], NSConditionallySetsEnabledBindingOption, nil]];
    [_timeoutStepper bind:NSEnabledBinding toObject:_scriptController withKeyPath:@"selection.applyTimeout" options:nil];
    
    [_timeoutUnitsPopUp bind:NSSelectedTagBinding toObject:_scriptController withKeyPath:@"selection.timeoutUnits" options:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], NSConditionallySetsEnabledBindingOption, nil]];
    [_timeoutUnitsPopUp bind:NSEnabledBinding toObject:_scriptController withKeyPath:@"selection.applyTimeout" options:nil];

    // use timeout
	[_useTimeoutButton bind:NSValueBinding toObject:_scriptController withKeyPath:@"selection.applyTimeout" options:nil];

}

/*
 
 set action
 
 */
- (void)setActionSpecifier:(MGSTaskSpecifier *)action
{
    BOOL updateOptions = YES;
    
    if (_actionSpecifier) {
        
        if ([_actionSpecifier isEqualUUID:action]) {
            updateOptions = NO;
        }
    }
    
	_actionSpecifier = action;
	MGSScript *script = [action script];
    [_scriptController setContent:script];

	// update options
    if (updateOptions) {
        [script applyTimeoutDefaults];
     }
}

@end
