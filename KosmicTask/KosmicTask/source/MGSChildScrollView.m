//
//  MGSChildScrollView.m
//  KosmicTask
//
//  Created by Mitchell Jonathan on 26/06/2012.
//  Copyright (c) 2012 Mugginsoft. All rights reserved.
//

#import "MGSChildScrollView.h"

@implementation MGSChildScrollView
@synthesize embedded;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.embedded = YES;
    }
    
    return self;
}

- (void)scrollWheel:(NSEvent *)theEvent
{
    /* this scrollview is embedded in another.
     by default the scrollview under the cursor gets
     the scrollWheel event. this causes scolling to halt whenever
     a child scollview is encountered.
     we only want to scroll our embedded scollview when it is first responder. 
     */
    id firstResponder = [[self window] firstResponder];
    if (firstResponder == [self documentView]) {
        [super scrollWheel:theEvent];
    } else {
        [[self nextResponder] scrollWheel:theEvent];
    }
}

@end
