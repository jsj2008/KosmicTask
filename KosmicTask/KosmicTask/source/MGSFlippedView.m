//
//  MGSFlippedView.m
//  Mother
//
//  Created by jonathan on 05/03/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MGSFlippedView.h"


@implementation MGSFlippedView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (BOOL)isFlipped
{
	return YES;
}

@end
