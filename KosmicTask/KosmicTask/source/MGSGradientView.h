//
//  MGSGradientView.h
//  Mother
//
//  Created by Jonathan on 06/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MGSGradientView : NSView {
	BOOL _hasTopBorder;
	BOOL _hasBottomBorder;
	NSColor *_startColor;
	NSColor *_endColor;
}

@property BOOL hasTopBorder;
@property BOOL hasBottomBorder;
@property (copy) NSColor *startColor;
@property (copy) NSColor *endColor;

+ (NSColor *)endColor;
+ (NSColor *)startColor;

@end
