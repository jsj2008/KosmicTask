//
//  NSWindowController_Mugginsoft.m
//  Mother
//
//  Created by Jonathan on 24/03/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "NSWindowController_Mugginsoft.h"


@implementation NSWindowController (Mugginsoft)

- (void)setControlsEnabled:(BOOL)enabled
{
	[[[self window] contentView] setControlsEnabled:enabled];
}
@end
