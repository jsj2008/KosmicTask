//
//  PlacardScrollView.h
//  Mother
//
//  Created by Jonathan on 17/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>


enum {
    PlacardLeft		= 0,		// default
    PlacardRight	= 1,
	PlacardRightCorner	= 2,	// MGS 17-05-08
};

@interface PlacardScrollView : NSScrollView {
    IBOutlet NSView *placard;
	IBOutlet NSView *_leftPlacard;
	int	_side;
	BOOL _placardVisible;
}

@property NSView *leftPlacard;
@property BOOL placardVisible;

- (void) setPlacard:(NSView *)inView;
- (NSView *) placard;
- (void) setSide:(int) inSide;
- (void)tilePlacardView:(NSView *)view side:(NSInteger)side;

@end

