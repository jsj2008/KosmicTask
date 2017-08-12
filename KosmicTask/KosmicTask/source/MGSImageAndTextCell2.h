//
//  MGSImageAndTextCell2.h
//  KosmicTask
//
//  Created by Jonathan on 16/06/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MGSImageAndTextCell2 : NSTextFieldCell
{
@private
	NSImage *image;
	NSColor * countBackgroundColour;
	NSInteger count;
	BOOL hasCount;
	NSImage *statusImage;
	NSImage *invertedStatusImage;
	NSInteger indentation;
	NSInteger countAlignment;
	NSInteger countMarginVertical;
}

@property NSInteger indentation;
@property NSInteger countAlignment;
@property NSInteger countMarginVertical;
@property (strong) NSImage *image;

+ (NSColor *)countColor;
+ (NSColor *)countColorGreen;

- (void)setStatusImage:(NSImage *)anImage;
- (NSImage*)statusImage;

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView*)controlView;
- (NSSize)cellSize;
- (void)setCountBackgroundColour:(NSColor *)newColour;
- (NSColor *)countBackgroundColour;

- (void)setCount:(NSInteger)value;
- (void)setHasCount:(BOOL)value;
- (BOOL)hasCount;

@end
