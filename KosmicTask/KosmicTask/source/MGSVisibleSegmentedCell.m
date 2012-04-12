//
//  MGSVisibleSegmentedCell.m
//  KosmicTask
//
//  Created by Mitchell Jonathan on 12/04/2012.
//  Copyright (c) 2012 Mugginsoft. All rights reserved.
//

#import "MGSVisibleSegmentedCell.h"

@implementation MGSVisibleSegmentedCell

- (void)drawSegment:(NSInteger)segment inFrame:(NSRect)frame withView:(NSView *)controlView
{
    if ([(NSSegmentedControl *)controlView isEnabledForSegment:segment]) {
        [super drawSegment:segment inFrame:frame withView:controlView];
    }
}
@end
