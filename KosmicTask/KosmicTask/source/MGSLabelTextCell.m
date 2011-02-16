//
//  MGSLabelTextCell.m
//  Mother
//
//  Created by Jonathan on 21/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSLabelTextCell.h"
#import "FVFinderLabel.h"

NSString *MGSLabelTextCellStringKey = @"string";
NSString *MGSLabelTextCellLabelIndexKey = @"labelIndex";

@implementation MGSLabelTextCell

@synthesize labelIndex = _labelIndex;

/*
 
 init
 
 */
- (id)init
{
	if ((self = [super init])) {
		self.labelIndex = 0;
	}
	return self;
}
/*
 
 init with coder
 
 */
- (id)initWithCoder:(NSCoder *)decoder
{
	self = [super initWithCoder:decoder];
	self.labelIndex = 0;
	return self;
}

/*
 
 draw interior with frame
 
 */
- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
	// draw label if index is valid
	if (self.labelIndex > 0 && self.labelIndex <= 7) {

		// get our gradient start and end colors from FVFinderLabel
		NSColor *endColor = [FVFinderLabel _lowerColorForFinderLabel:self.labelIndex];
		NSColor *startColor = [FVFinderLabel _upperColorForFinderLabel:self.labelIndex];
		
		
		NSBezierPath *labelPath =  [NSBezierPath bezierPathWithRoundedRect:cellFrame xRadius:4 yRadius:4];
		if ([self isHighlighted]) {
			[endColor set];
			[labelPath stroke];
			
			NSRect markerRect;
			
			// draw marker on cell right
			NSDivideRect(cellFrame, &markerRect, &cellFrame, cellFrame.size.height, NSMaxXEdge);
			labelPath = [NSBezierPath bezierPathWithRoundedRect:markerRect xRadius:4 yRadius:4];
		}
		
		NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:startColor endingColor:endColor];
		[gradient drawInBezierPath:labelPath angle:90];
	}

	
	// super implementation draws text
	[super drawInteriorWithFrame:cellFrame inView:controlView];
}

/*
 
 set object value
 
 */
- (void)setObjectValue:(id)object
{
	// set super class object
	if ([object isKindOfClass:[NSString class]]) {
		self.labelIndex = 0;
		[super setObjectValue:object];
		return;
	} 
	if ([object isKindOfClass:[NSDictionary class]]) {
		[super setObjectValue:[object objectForKey:MGSLabelTextCellStringKey]];
		self.labelIndex = [[object objectForKey:MGSLabelTextCellLabelIndexKey] integerValue];
	}
	
}

@end
