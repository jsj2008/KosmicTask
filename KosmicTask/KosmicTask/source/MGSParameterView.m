//
//  MGSParameterView.m
//  Mother
//
//  Created by Jonathan on 05/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSParameterView.h"
#import "MGSViewDraggingProtocol.h"

NSString *MGSParameterViewPBoardType = @"MGSParameterViewPBoardType";
NSString *MGSInputParameterPBoardType = @"MGSInputParameterPBoardType";
NSString *MGSInputParameterPBoard = @"MGSInputParameterPBoard";

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

#pragma mark -
#pragma mark NSDraggingDestination protocol

/*
 
 - draggingEntered:
 
 */
- (NSDragOperation)draggingEntered:(id < NSDraggingInfo >)sender
{
    if ([self.delegate respondsToSelector:@selector(draggingEntered:object:)]) {
        return [self.delegate draggingEntered:sender object:self];
    }
    
    return NSDragOperationNone;
}


/*
 
 - draggingUpdated:
 
 */
- (NSDragOperation)draggingUpdated:(id < NSDraggingInfo >)sender
{
    if ([self.delegate respondsToSelector:@selector(draggingUpdated:object:)]) {
        return [self.delegate draggingUpdated:sender object:self];
    }
    
    return NSDragOperationNone;
}

/*
 
 - draggingExited:
 
 */
- (void)draggingExited:(id < NSDraggingInfo >)sender
{
    if ([self.delegate respondsToSelector:@selector(draggingExited:object:)]) {
        [self.delegate draggingExited:sender object:self];
    }
}

/*
 
 - prepareForDragOperation:
 
 */
- (BOOL)prepareForDragOperation:(id < NSDraggingInfo >)sender
{
    if ([self.delegate respondsToSelector:@selector(prepareForDragOperation:object:)]) {
        [self.delegate prepareForDragOperation:sender object:self];
    }
    
    return NO;
}

/*
 
 - performDragOperation:
 
 */
- (BOOL)performDragOperation:(id < NSDraggingInfo >)sender
{
    if ([self.delegate respondsToSelector:@selector(performDragOperation:object:)]) {
        return [self.delegate performDragOperation:sender object:self];
    }
    
    return NO;

}

/*
 
 - concludeDragOperation:
 
 */
- (void)concludeDragOperation:(id < NSDraggingInfo >)sender
{
    if ([self.delegate respondsToSelector:@selector(concludeDragOperation:object:)]) {
        [self.delegate concludeDragOperation:sender object:self];
    }
    
}

/*
 
 - draggingEnded:
 
 */
- (void)draggingEnded:(id < NSDraggingInfo >)sender
{
    if ([self.delegate respondsToSelector:@selector(draggingEnded:object:)]) {
        [self.delegate draggingEnded:sender object:self];
    }
    
}

@end
