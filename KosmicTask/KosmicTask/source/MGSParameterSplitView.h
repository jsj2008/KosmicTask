//
//  MGSParameterSplitView.h
//  Mother
//
//  Created by Jonathan on 08/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSExpandingSplitview.h"

@interface MGSParameterSplitView : MGSExpandingSplitview {
    NSPoint _prevMouseLoc;
	BOOL _isDragging;
	BOOL _restrictSubViewHeight;
	NSMutableArray *_resizableParameters;
    id _delegate;
}

@property BOOL isDragging;
@property id delegate;

//- (void)subView:(NSView *)view resizeViewWithNewSize:(NSSize)newSize;
@end
