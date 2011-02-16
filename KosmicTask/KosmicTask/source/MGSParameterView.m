//
//  MGSParameterView.m
//  Mother
//
//  Created by Jonathan on 05/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSParameterView.h"

@implementation MGSParameterView

/*
 
 init with frame
 
 */
- (id)initWithFrame:(NSRect)frameRect
{
	if ([super initWithFrame:frameRect]) {
		self.maxXMargin = 8;
		self.minXMargin = 8;
		self.minYMargin = 13;
		self.maxYMargin = 2;
		self.bannerHeight = 25;
	}
	return self;
}


@end
