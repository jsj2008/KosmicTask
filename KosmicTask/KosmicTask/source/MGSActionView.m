//
//  MGSActionView.m
//  Mother
//
//  Created by Jonathan on 23/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSActionView.h"


@implementation MGSActionView


/*
 
 init with frame
 
 */
- (id)initWithFrame:(NSRect)frameRect
{
	if ([super initWithFrame:frameRect]) {
		self.maxXMargin = 8;
		self.minXMargin = 8;
		self.minYMargin = 13;
		self.maxYMargin = 10;
		self.bannerHeight = 25.0f;
		
		// set gradient colours
		self.bannerStartColor = [NSColor colorWithCalibratedRed:0.773f green:0.773f blue:0.773f alpha:1.0f];
		self.bannerMidColor = [NSColor colorWithCalibratedRed:0.671f green:0.671f blue:0.671f alpha:1.0f];
		self.bannerEndColor = [NSColor colorWithCalibratedRed:0.588f green:0.588f blue:0.588f alpha:1.0f];	
	}
	return self;
}
@end
