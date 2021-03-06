//
//  MGSLCDDisplayView.h
//  Mother
//
//  Created by Jonathan on 11/08/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MGSLCDDisplayView : NSView {
	NSImage *_displayImage;
	NSImage *_activeDisplayImage;
	NSImage *_unavailableDisplayImage;
	BOOL _maxIntensity;
	CGFloat _opacityDelta;
	BOOL _active;
	BOOL _available;
}

@property BOOL maxIntensity;
@property (getter=isActive) BOOL active;
@property (getter=isAvailable) BOOL available;
@end
