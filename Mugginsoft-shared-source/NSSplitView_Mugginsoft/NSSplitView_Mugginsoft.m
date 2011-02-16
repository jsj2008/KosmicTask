//
//  MGSViewBehaviour.m
//  Mother
//
//  Created by Jonathan on 31/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "NSSplitView_Mugginsoft.h"

@implementation NSSplitView(Mugginsoft)

/*
 
 resize subviews with old size, with behaviour
 
 */
- (void)resizeSubviewsWithOldSize:(NSSize)oldSize withBehaviour:(MGSSplitviewBehaviour)behaviour
{
	[self resizeSubviewsWithOldSize:oldSize withBehaviour:behaviour minSizes:nil];
}

/*
 resize subviews with old size, with behaviour and min sizes
 
 apply splitview behaviour
 
 note that NSSplitView uses flipped coordinates.
 
 subview at index 0 is leftmost or topmost
 x,y 0,0, is top left
 
 */
- (void)resizeSubviewsWithOldSize:(NSSize)oldSize withBehaviour:(MGSSplitviewBehaviour)behaviour minSizes:(NSArray *)minSizes
{
	if (behaviour == MGSSplitviewBehaviourNone) {
		return;
	}
	
	NSRect newFrame = [self frame];
	NSSize newSize = newFrame.size;
	CGFloat heightDelta = newSize.height - oldSize.height;
	CGFloat dividerThickness = [self dividerThickness];

	int subviewCount = [[self subviews] count];
	
	NSRect rect0 = [[[self subviews] objectAtIndex:0] frame];
	NSRect rect1 = [[[self subviews] objectAtIndex:1] frame];
	NSRect rect2;
	NSString *assertMsg = @"invalid splitview behaviour";
	CGFloat minSize0 = -1, minSize1 = -1, minSize2 = -1;
	CGFloat height0 = 0, height1= 0, height2 = 0, height1Delta = 0;
	CGFloat width0 = 0, width1= 0;
	
	// if minsizes defined
	if (minSizes) {
		// min sizes are widths or heights depending on context
		if ([minSizes count] >= 1) minSize0 = [[minSizes objectAtIndex:0] doubleValue];
		if ([minSizes count] >= 2) minSize1 = [[minSizes objectAtIndex:1] doubleValue];
		if ([minSizes count] >= 3) minSize2 = [[minSizes objectAtIndex:2] doubleValue];
	}
	
	switch (subviewCount) {

		case 2:
			if ([self isVertical]) {	// views are side by side
				rect0.origin = NSMakePoint(0, 0);
				rect0.size.height = newFrame.size.height;
				rect1.size.height = newFrame.size.height;
				
				if (behaviour == MGSSplitviewBehaviourOf2ViewsFirstFixed) {
					
					// keep view at index 0 at current width
					// adjust view at index 1 accordingly
					width1 = newFrame.size.width - rect0.size.width - dividerThickness;
					if (width1 < minSize1) {
						width1 = minSize1;
					}

					// if rect0 is below its min size but rect1 can accomodate it at its min size then allow this
					if (rect0.size.width < minSize0) {
						if (newFrame.size.width - minSize0 - dividerThickness >= minSize1) {
							width1 = newFrame.size.width - minSize0 - dividerThickness;
						}
					}
					
					rect1.size.width = width1;
					rect0.size.width = newFrame.size.width - rect1.size.width - dividerThickness;
					rect1.origin = NSMakePoint(rect0.size.width + dividerThickness, 0);
					
				} else if (behaviour == MGSSplitviewBehaviourOf2ViewsSecondFixed) {
					
					// keep view at index 1 at current width
					// adjust view at index 0 accordingly
					width0 = newFrame.size.width - rect1.size.width - dividerThickness;
					if (width0 < minSize0) {
						width0 = minSize0;
					}
					
					// if rect1 is below its min size but rect0 can accomodate it at its min size then allow this
					if (rect1.size.width < minSize1) {
						if (newFrame.size.width - minSize1 - dividerThickness >= minSize0) {
							width0 = newFrame.size.width - minSize1 - dividerThickness;
						}
					}
					
					rect0.size.width = width0;
					rect1.size.width = newFrame.size.width - rect0.size.width - dividerThickness;
					rect1.origin = NSMakePoint(rect0.origin.x + rect0.size.width + dividerThickness, 0);

				} else {
					NSAssert(NO, assertMsg);
				}
				
			} else {
				
				// views one above the other
				rect0.origin = NSMakePoint(0, 0);	// this reqd in cases where number of views has decreased from 3 to 2
				rect0.size.width = newFrame.size.width;
				rect1.size.width = newFrame.size.width;
				
				if (behaviour == MGSSplitviewBehaviourOf2ViewsFirstFixed) {
					
					// keep view at index 0 at current height
					// adjust view at index 1 accordingly
					height1 = newFrame.size.height - rect0.size.height - dividerThickness;
					if (height1 < minSize1) {
						rect1.size.height = minSize1;
						rect0.size.height = newFrame.size.height - rect1.size.height - dividerThickness;
					} else {
						rect1.size.height = height1;
					}
				} else if (behaviour == MGSSplitviewBehaviourOf2ViewsSecondFixed) {	
					
					// keep view at index 1 at current height
					// adjust view at index 0 accordingly
					height0 = newFrame.size.height - rect1.size.height - dividerThickness;
					if (height0 < minSize0) {
						rect0.size.height = minSize0;
						rect1.size.height = newFrame.size.height - rect0.size.height - dividerThickness;
					} else {
						rect0.size.height = height0;
					}
					
				} else {
					NSAssert(NO, assertMsg);
				}
				
				rect1.origin = NSMakePoint(0, rect0.size.height + dividerThickness);
			}
			
			[[[self subviews] objectAtIndex:0] setFrame:rect0];
			[[[self subviews] objectAtIndex:1] setFrame:rect1];
			
			break;
			
		case 3:
			rect2 = [[[self subviews] objectAtIndex:2] frame];
			
			if ([self isVertical]) {	// views are side by side
				
				if (behaviour == MGSSplitviewBehaviourOf3ViewsFirstAndSecondFixed) {
					
					// keep views at index 0 and 1 at current width
					// adjust view at index 2 accordingly
					
					rect0.origin = NSMakePoint(0, 0);
					rect0.size.height = newFrame.size.height;
					
					rect1.origin = NSMakePoint(rect0.size.width + dividerThickness, 0);
					rect1.size.height = newFrame.size.height;

					rect2.origin = NSMakePoint(rect1.origin.x + rect1.size.width + dividerThickness, 0);
					rect2.size.width = newFrame.size.width - rect0.size.width - rect1.size.width - 2 * dividerThickness;
					rect2.size.height = newFrame.size.height;
					
				} else {
					NSAssert(NO, assertMsg);
				}
				
			} else {	// views are on top of each other
				
				if (behaviour == MGSSplitviewBehaviourOf3ViewsFirstAndThirdFixed) {

					rect0.origin = NSMakePoint(0, 0);
					rect0.size.width = newFrame.size.width;
					rect1.size.width = newFrame.size.width;
					rect2.size.width = newSize.width;

					height1 = [[[self subviews] objectAtIndex:1] frame].size.height;
					height1 += heightDelta;

					if (height1 >= minSize1) {

						// keep views at index 0 and 2 at current height
						// adjust view at index 1 accordingly
						rect1.origin = NSMakePoint(0, rect0.size.height + dividerThickness);
						height1 = newFrame.size.height - rect0.size.height - rect2.size.height - 2 * dividerThickness;
						
						// revalidate our height as this method is also called whenever subviews are added to the splitview
						// in which case we need to ensure that even though the frame size has not changed that the views
						// do not go beneath then minimum sizes
						if (height1 >= minSize1) {
							rect1.size.height = height1;						
							rect2.origin = NSMakePoint(0, rect1.origin.y + rect1.size.height + dividerThickness);
						}
					} 
					
					// if view height is too small then redistribute view heights accordingly
					if (height1 < minSize1) {
						
						// adjust request view to min height
						height1Delta = height1 - minSize1;
						heightDelta += height1Delta;
						
						// calc view heights
						height1 = minSize1;
						height0 = [[[self subviews] objectAtIndex:0] frame].size.height;
						height0 += heightDelta;
						if (height0 < minSize0) {
							height0 = minSize0;
						}
						height2 = newSize.height - 2 * dividerThickness - height0 - height1;
						
						rect0.size.height = height0;
						
						rect1.origin.y = rect0.origin.y + rect0.size.height + dividerThickness;
						rect1.size.height = height1;
						
						rect2.origin.y = rect1.origin.y + rect1.size.height +dividerThickness;
						rect2.size.height = height2;
					}
					
					
				} else {
					NSAssert(NO, assertMsg);
				}	
				
			}
			
			[[[self subviews] objectAtIndex:0] setFrame:rect0];
			[[[self subviews] objectAtIndex:1] setFrame:rect1];
			[[[self subviews] objectAtIndex:2] setFrame:rect2];
			
			break;
			
		default:
			NSAssert(NO, @"invalid number of subviews");
	}
}

/*
- (void)replaceSubview:(NSView *)oldView withViewSizedAsOld:(NSView *)newView 
{
	[newView setFrameSize:[oldView frame].size];	// make newView same size as oldView
	[self replaceSubview:oldView with:newView];
}
*/

/*
 
 log the subview frames
 
 */
- (void)logSubviewFrames
{
	// spliview coordinate system IS flipped
	NSLog(@"Splitview is flipped: %@", [self isFlipped] ? @"YES" : @"NO");
	
	for (int i = 0; i < [[self subviews] count]; i++) {
		NSRect frame = [[[self subviews] objectAtIndex:i] frame];
		NSLog(@"subview %i : origin.x = %f : origin.y = %f : size.width = %f : size.height = %f", i, frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
	}
}
@end
