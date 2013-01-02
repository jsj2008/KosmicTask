//
//  MGSParameterEndView.m
//  Mother
//
//  Created by Jonathan on 01/07/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSParameterEmptyView.h"
#import "MGSParameterView.h"

@implementation MGSParameterEmptyView

/*
 
 - initWithFrame:
 
 */
- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        
        [self registerForDraggedTypes:@[MGSParameterViewPBoardType]];
        
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
	
	#pragma unused(rect)
	
    // Drawing code here.
}

@end
