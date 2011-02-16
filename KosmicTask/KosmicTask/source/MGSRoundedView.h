//
//  MGSRoundedView.h
//  Mother
//
//  Created by Jonathan on 06/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum _MGSViewGradientType {
	MGSViewGradientToolbar = 0, MGSViewGradientTableView, MGSViewGradientBanner
} MGSViewGradientType;

@interface MGSRoundedView : NSView {
	MGSViewGradientType _gradientType;
	BOOL _showDragRect;
}

- (NSRect)splitViewRect;

@property MGSViewGradientType gradientType;
@property BOOL showDragRect;
@end
