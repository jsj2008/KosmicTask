//
//  MGSLabelTextCell.m
//  Mother
//
//  Created by Jonathan on 21/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSLabelLevelIndicatorCell.h"
#import "FVFinderLabel.h"

NSString *MGSLabelLevelIndicatorCellRatingKey = @"rating";
NSString *MGSLabelLevelIndicatorCellLabelIndexKey = @"labelIndex";

@implementation MGSLabelLevelIndicatorCell

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
 
 draw with frame
 
 drawInteriorWithFrame:inView does not seem to be sent by NSLevelIndicatorCell
 
 */
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{

	// draw label if index is valid
	if (self.labelIndex > 0 && self.labelIndex <= 7) {
	
		// get our gradient start and end colors from FVFinderLabel
		NSColor *endColor = [FVFinderLabel _lowerColorForFinderLabel:self.labelIndex];
		NSColor *startColor = [FVFinderLabel _upperColorForFinderLabel:self.labelIndex];
		
		// form path
		NSBezierPath *labelPath = [NSBezierPath bezierPathWithRoundedRect:cellFrame xRadius:4 yRadius:4];
		
		// draw label
		if (![self isHighlighted]) {
			NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:startColor endingColor:endColor];
			[gradient drawInBezierPath:labelPath angle:90];
		} else {
			[endColor set];
			[labelPath stroke];
		}
	
	}

	// super implementation draws rating
	[super drawWithFrame:cellFrame inView:controlView];
}
/*
 
 set object value
 
 */
- (void)setObjectValue:(id)object
{
	// set super class object
	if ([object isKindOfClass:[NSNumber class]]) {
		self.labelIndex = 0;
		[super setObjectValue:object];
		return;
	} 
	if ([object isKindOfClass:[NSDictionary class]]) {
		[super setObjectValue:[object objectForKey:MGSLabelLevelIndicatorCellRatingKey]];
		self.labelIndex = [[object objectForKey:MGSLabelLevelIndicatorCellLabelIndexKey] integerValue];
	}
	
}

@end
