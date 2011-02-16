//
//  MGSImageAndText.h
//  Mother
//
//  Created by Jonathan on 16/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *MGSImageAndTextValueKey;

typedef enum _MGSAlignment {
	MGSAlignRight = 0, 
	MGSAlignLeft,
} MGSAlignment;

@interface MGSImageAndText : NSObject {
	id _value;
	NSInteger _indentation;
	NSImage *_image;
	NSInteger _count;
	BOOL _hasCount;
	NSColor *_countColor;
	NSImage *_statusImage;
	NSInteger _countAlignment;
}

- (NSComparisonResult)compare:(MGSImageAndText *)object;

@property id value;
@property NSInteger indentation;
@property (assign) NSImage *image;
@property NSInteger count;
@property BOOL hasCount;
@property (assign) NSColor *countColor;
@property (copy) NSImage *statusImage;
@property NSInteger countAlignment;

@end
