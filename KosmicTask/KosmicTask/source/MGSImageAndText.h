//
//  MGSImageAndText.h
//  Mother
//
//  Created by Jonathan on 16/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *MGSImageAndTextValueKey;

enum _MGSAlignment {
	MGSAlignRight = 0, 
	MGSAlignLeft,
};
typedef NSInteger MGSAlignment;

@interface MGSImageAndText : NSObject {
	id _value;
	NSInteger _indentation;
	NSImage *__strong _image;
	NSInteger _count;
	BOOL _hasCount;
	NSColor *_countColor;
	NSImage *_statusImage;
	NSInteger _countAlignment;
}

- (NSComparisonResult)compare:(MGSImageAndText *)object;

@property id value;
@property NSInteger indentation;
@property (strong) NSImage *image;
@property NSInteger count;
@property BOOL hasCount;
@property  NSColor *countColor;
@property (copy) NSImage *statusImage;
@property NSInteger countAlignment;

@end
