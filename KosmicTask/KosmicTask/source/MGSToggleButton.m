//
//  MGSToggleButton.m
//  Mother
//
//  Created by Jonathan on 04/02/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSToggleButton.h"


@implementation MGSToggleButton

@synthesize onStateImage = _onStateImage;
@synthesize onStateAltImage = _onStateAltImage;
@synthesize onStateDisabledImage = _onStateDisabledImage;
@synthesize offStateImage = _offStateImage;
@synthesize offStateAltImage = _offStateAltImage;
@synthesize offStateDisabledImage = _offStateDisabledImage;
@synthesize mixedStateImage = _mixedStateImage;
@synthesize mixedStateAltImage = _mixedStateAltImage;
@synthesize mixedStateDisabledImage = _mixedStateDisabledImage;
@synthesize state = _state;

/*
 
 init with coder
 
 */
- (id)initWithCoder:(NSCoder *)aCoder 
{
	self = [super initWithCoder:aCoder];
	
	[self setButtonType:NSMomentaryChangeButton];
	[self setState:NSOnState];
	
	return self;
}


/*
 
 set state
 
 */
- (void)setState:(NSInteger)state
{
	_state = state;
	if (state == NSOnState) {
		[self setImage:_onStateImage];
		[self setAlternateImage:_onStateAltImage];
	} else if (state == NSOffState) {
		[self setImage:_offStateImage];
		[self setAlternateImage:_offStateAltImage];
	} else {
		[self setImage:_mixedStateImage];
		[self setAlternateImage:_mixedStateAltImage];
	}
}
/*
 
 set enabled
 
 */
- (void)setEnabled:(BOOL)value
{
	[super setEnabled:value];
	
	if (!value) {
		if (_state == NSOnState) {
			[self setImage:_onStateDisabledImage];
		} else if (_state == NSOffState) {
			[self setImage:_offStateDisabledImage];
		} else {
			[self setImage:_mixedStateDisabledImage];
		}
	} else {
		[self setState:_state];		
	}
}
@end
