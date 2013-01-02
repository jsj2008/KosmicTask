//
//  MGSParameterEndViewController.m
//  Mother
//
//  Created by Jonathan on 12/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSParameterEndViewController.h"
#import "MGSCapsuleTextCell.h"
#import "MGSParameterView.h"

@interface MGSParameterEndViewController()
- (MGSParameterView *)parameterView;
- (MGSCapsuleTextCell *)capsuleTextCellForTextField:(NSTextField *)textField;
@end

@implementation MGSParameterEndViewController

@synthesize inputSegmentedControl;
@synthesize contextPopupButton;
@synthesize delegate;

/*
 
 init
 
 */
- (id)init
{
	if ([super initWithNibName:@"ParameterEndView" bundle:nil]) {
	}
	return self;
}

/*
 
 awake from nib
 
 */
- (void)awakeFromNib
{
    MGSCapsuleTextCell *cell = [self capsuleTextCellForTextField: _textField];
	if (cell) {
		[cell setCapsuleHasShadow:NO];
        _capsuleBackgroundColor = [cell backgroundColor];
	}
    _capsuleDragBackgroundColor = [[MGSParameterView class] dragTargetOutlineColor];
    
    [[self parameterView] registerForDraggedTypes:@[MGSParameterViewPBoardType]];
    [[self parameterView] setDelegate:self];
    [[self parameterView] setPanelStyle:kMGSRoundedPanelViewStyleEmptyParameter];

}

/*
 
 - capsuleTextCellForTextField:
 
 */
- (MGSCapsuleTextCell *)capsuleTextCellForTextField:(NSTextField *)textField
{
    MGSCapsuleTextCell *cell = nil;
    
	if ([[textField cell] isKindOfClass:[MGSCapsuleTextCell class]]) {
        cell = (MGSCapsuleTextCell *)[textField cell];
    }
    
    return cell;
}
/*
 
 - parameterView
 
 */
- (MGSParameterView *)parameterView
{
    NSView *view = self.view;
    NSAssert([view isKindOfClass:[MGSParameterView class]], @"bad view class");
    
    return (MGSParameterView *)view;
}

#pragma mark -
#pragma mark Accessors

/*
 
 - setIsDragTarget:
 
 */
- (void)setIsDragTarget:(BOOL)isDragTarget
{
    MGSCapsuleTextCell *cell = [self capsuleTextCellForTextField: _textField];
    if (isDragTarget) {
        cell.backgroundColor = _capsuleDragBackgroundColor;
    } else {
        cell.backgroundColor = _capsuleBackgroundColor;
    }
    [self parameterView].isDragTarget = isDragTarget;
}
#pragma mark -
#pragma mark MGSViewDraggingProtocol protocol

/*
 
 - draggingEntered:object:
 
 */
- (NSDragOperation)draggingEntered:(id < NSDraggingInfo >)sender object:(id)object
{
    NSAssert(object == self.view, @"Bad class");
    
    if ([self.delegate respondsToSelector:@selector(draggingEntered:object:)]) {
        return [self.delegate draggingEntered:sender object:self];
    }
    
    return NSDragOperationNone;
}


/*
 
 - draggingUpdated:object:
 
 */
- (NSDragOperation)draggingUpdated:(id < NSDraggingInfo >)sender object:(id)object
{
#pragma unused(object)
    
    if ([self.delegate respondsToSelector:@selector(draggingUpdated:object:)]) {
        return [self.delegate draggingUpdated:sender object:self];
    }
    
    
    return NSDragOperationNone;
}

/*
 
 - draggingExited:object:
 
 */
- (void)draggingExited:(id < NSDraggingInfo >)sender object:(id)object
{
#pragma unused(object)
    
    if ([self.delegate respondsToSelector:@selector(draggingExited:object:)]) {
        [self.delegate draggingExited:sender object:self];
    }
}

/*
 
 - prepareForDragOperation:object:
 
 */
- (BOOL)prepareForDragOperation:(id < NSDraggingInfo >)sender object:(id)object
{
#pragma unused(object)
    
    if ([self.delegate respondsToSelector:@selector(prepareForDragOperation:object:)]) {
        return [self.delegate prepareForDragOperation:sender object:self];
    }
    
    return NO;
}

/*
 
 - performDragOperation:object:
 
 */
- (BOOL)performDragOperation:(id < NSDraggingInfo >)sender object:(id)object
{
#pragma unused(object)
    
    if ([self.delegate respondsToSelector:@selector(performDragOperation:object:)]) {
        return [self.delegate performDragOperation:sender object:self];
    }
    
    return NO;
    
}

/*
 
 - concludeDragOperation:object:
 
 */
- (void)concludeDragOperation:(id < NSDraggingInfo >)sender object:(id)object
{
#pragma unused(object)
    
    if ([self.delegate respondsToSelector:@selector(concludeDragOperation:object:)]) {
        [self.delegate concludeDragOperation:sender object:self];
    }
    
}

/*
 
 - draggingEnded:object:
 
 */
- (void)draggingEnded:(id < NSDraggingInfo >)sender object:(id)object
{
#pragma unused(object)

    
    if ([self.delegate respondsToSelector:@selector(draggingEnded:object:)]) {
        [self.delegate draggingEnded:sender object:self];
    }
    
}

@end
