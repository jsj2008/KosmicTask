//
// File:	   MGSImageAndTextCell.m
//
// Modified from the Apple example code.
// Includes counter drawing code from Vienna RSS reader (BSD Licence)
//

#import "MGSImageAndTextCell.h"
//#import "BaseNode.h"	// original apple node class
#import "MGSOutlineViewNode.h"
#import "NSBezierPath_Mugginsoft.h"
#import "MGSImageAndText.h"
#import "NSString_Mugginsoft.h"
#import "MLog.h"

#define kIconImageSize		16

#define kImageOriginXOffset 3
#define kImageOriginYOffset 1

#define kTextOriginXOffset	2
#define kTextOriginYOffset	2
#define kTextHeightAdjust	4

#define kMinCapsuleWidth 20

@implementation MGSImageAndTextCell

@synthesize indentation;
@synthesize countAlignment;
@synthesize countMarginVertical;


+ (NSColor *)countColor
{
	return [NSColor colorWithCalibratedRed:0.522f green:0.592f blue:0.733f alpha:1.0f];
}

+ (NSColor *)countColorGreen
{
	return [NSColor colorWithCalibratedRed:0.349f green:0.529f blue:0.122f alpha:1.0f];
	//return [NSColor colorWithCalibratedRed:0.976 green:0.259 blue:0.259 alpha:1.0]; // red
	
}
// -------------------------------------------------------------------------------
//	awakeFromNib:
// ------------------------------------------------------------------------------

- (void) awakeFromNib
{
	// we want a smaller font
	//[self setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];

	statusImage = nil;
	invertedStatusImage = nil;
	indentation = 0;
	countAlignment = MGSAlignRight;
	countMarginVertical = 3;
	
	// blue background a la Mail.app
	[self setCountBackgroundColour:[MGSImageAndTextCell countColor]];
}

/* setCountBackgroundColour
 * Sets the colour used for the count button background.
 */
-(void)setCountBackgroundColour:(NSColor *)newColour
{
	[newColour retain];
	[countBackgroundColour release]; 
	countBackgroundColour = newColour;
}
-(NSColor *)countBackgroundColour
{
	return countBackgroundColour;
}
// -------------------------------------------------------------------------------
//	dealloc:
// -------------------------------------------------------------------------------
- (void)dealloc
{
    [image release];
    image = nil;
    [super dealloc];
}

// -------------------------------------------------------------------------------
//	copyWithZone:zone
// -------------------------------------------------------------------------------
- (id)copyWithZone:(NSZone*)zone
{
    MGSImageAndTextCell *cell = (MGSImageAndTextCell*)[super copyWithZone:zone];
    cell->image = [image retain];
    return cell;
}

// -------------------------------------------------------------------------------
//	setImage:anImage
// -------------------------------------------------------------------------------
- (void)setImage:(NSImage*)anImage
{
    if (anImage != image)
	{
        [image release];
        image = [anImage retain];
		[image setSize:NSMakeSize(kIconImageSize, kIconImageSize)];
		
    }
}

// -------------------------------------------------------------------------------
//	image:
// -------------------------------------------------------------------------------
- (NSImage*)image
{
    return image;
}

- (void)setStatusImage:(NSImage*)anImage
{
    if (anImage != statusImage)
	{
        [statusImage release];
        statusImage = [anImage retain];
		[statusImage setSize:NSMakeSize(kIconImageSize, kIconImageSize)];
		
		NSImageCell *imageCell = [[NSImageCell alloc] initImageCell:statusImage];
		[imageCell setBackgroundStyle:NSBackgroundStyleDark];
		
		// NSCell - preparedImage does not seem to be declared in NSCell.h
		// hence use performSelector to silence compiler
		//invertedStatusImage = (NSImage *)[imageCell preparedImage];
#pragma mark warning what happened to NSCell - preparedImage
		/*
		SEL preparedImageSelector = @selector(preparedImage);
		invertedStatusImage = [imageCell respondsToSelector:preparedImageSelector] 
									? [imageCell performSelector:preparedImageSelector] : nil;
		 */
		invertedStatusImage = statusImage;
		
    }
}

- (NSImage*)statusImage
{
    return statusImage;
}
// -------------------------------------------------------------------------------
//	isGroupCell:
// -------------------------------------------------------------------------------
- (BOOL)isGroupCell
{
    return ([self image] == nil && [[self title] length] > 0);
}

// -------------------------------------------------------------------------------
//	titleRectForBounds:cellRect
//
//	Returns the proper bound for the cell's title while being edited
// -------------------------------------------------------------------------------
- (NSRect)titleRectForBounds:(NSRect)cellRect
{	
	// the cell has an image: draw the normal item cell
	NSSize imageSize;
	NSRect imageFrame;

	imageSize = [image size];
	NSDivideRect(cellRect, &imageFrame, &cellRect, 3 + imageSize.width, NSMinXEdge);

	imageFrame.origin.x += kImageOriginXOffset;
	imageFrame.origin.y -= kImageOriginYOffset;
	imageFrame.size = imageSize;
	
	imageFrame.origin.y += ceilf((cellRect.size.height - imageFrame.size.height) / 2);
	
	NSRect newFrame = cellRect;
	newFrame.origin.x += kTextOriginXOffset;
	newFrame.origin.y += kTextOriginYOffset;
	newFrame.size.height -= kTextHeightAdjust;

	return newFrame;
}

// -------------------------------------------------------------------------------
//	editWithFrame:inView:editor:delegate:event
// -------------------------------------------------------------------------------
- (void)editWithFrame:(NSRect)aRect inView:(NSView*)controlView editor:(NSText*)textObj delegate:(id)anObject event:(NSEvent*)theEvent
{
	NSRect textFrame = [self titleRectForBounds:aRect];
	[super editWithFrame:textFrame inView:controlView editor:textObj delegate:anObject event:theEvent];
}

// -------------------------------------------------------------------------------
//	selectWithFrame:inView:editor:delegate:event:start:length
// -------------------------------------------------------------------------------
- (void)selectWithFrame:(NSRect)aRect inView:(NSView*)controlView editor:(NSText*)textObj delegate:(id)anObject start:(int)selStart length:(int)selLength
{
	NSRect textFrame = [self titleRectForBounds:aRect];
	[super selectWithFrame:textFrame inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

// -------------------------------------------------------------------------------
//	drawWithFrame:inView:
// -------------------------------------------------------------------------------
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{	
	BOOL cellFrameModified = NO;
	
	// indent
	CGFloat xOffset = indentation * 12;
	cellFrame.origin.x += xOffset;
	cellFrame.size.width -= xOffset;

	// the cell has an image: draw the normal item cell
	NSSize imageSize;
	NSRect imageFrame;
	
	if (image != nil)
	{
		// we need to pass in a 16x16 ish image here.
		// if image is larger than it will be drawn larger
		imageSize = [image size];	// this way we need to pass in a correctly sized image
				
        NSDivideRect(cellFrame, &imageFrame, &cellFrame, 3 + imageSize.width, NSMinXEdge);
 
        imageFrame.origin.x += kImageOriginXOffset;
		imageFrame.origin.y -= kImageOriginYOffset;
        imageFrame.size = imageSize;

		if ([controlView isFlipped])
		   imageFrame.origin.y += ceilf((cellFrame.size.height + imageFrame.size.height) / 2);
		else
			imageFrame.origin.y += ceilf((cellFrame.size.height - imageFrame.size.height) / 2);
		
		// draw entire image
		// method is deprecated 
		[image compositeToPoint:imageFrame.origin operation:NSCompositeSourceOver];

		cellFrameModified = YES;
	}
	
	// If the cell has a count button, draw the count
	// button on the right of the cell.
	if (hasCount) {
		//NSSize stringSize = [[self attributedStringValue] size];
		
		NSString * number = [NSString stringWithFormat:@"%i", count];
		
		// Use the current font point size as a guide for the count font size
		float pointSize = [[self font] pointSize];
		
		// flip font and capsule colors when highlighted
		NSColor *fontColor, *capsuleColor;
		if ([self isHighlighted]) {
			fontColor = countBackgroundColour;
			capsuleColor = [NSColor whiteColor];
		} else {
			fontColor = [NSColor whiteColor];
			capsuleColor = countBackgroundColour;
		}
		
		// Create attributes for drawing the count.
		NSDictionary * attributes = [[NSDictionary alloc] initWithObjectsAndKeys:[NSFont fontWithName:@"Helvetica-Bold" size:pointSize],
									 NSFontAttributeName,
									 fontColor,
									 NSForegroundColorAttributeName,
									 nil];
		NSSize numSize = [number sizeWithAttributes:attributes];
		
		// Compute the dimensions of the count rectangle.
		int cellWidth = MAX(numSize.width + 6, numSize.height + 1) + 1;
		if (cellWidth < kMinCapsuleWidth) {
			cellWidth = kMinCapsuleWidth;
		}
		
		NSRect countFrame;
		
		// can align count on left or right
		if (countAlignment == MGSAlignRight) {
			NSDivideRect(cellFrame, &countFrame, &cellFrame, cellWidth + 4, NSMaxXEdge);
		} else {
			NSDivideRect(cellFrame, &countFrame, &cellFrame, cellWidth + 4, NSMinXEdge);
		}
		
		if ([self drawsBackground])
		{
			[[self backgroundColor] set];
			NSRectFill(countFrame);
		}
		
		if (countAlignment == MGSAlignRight) {
			countFrame.origin.y += countMarginVertical;	// Mail.app has similar clearances to these
			countFrame.size.height -= (2 * countMarginVertical);
			countFrame.size.width -= 4;	// clearance on right of capsule
		} else {
			countFrame.origin.y += countMarginVertical;	// Mail.app has similar clearances to these
			countFrame.size.height -= (2 * countMarginVertical);
			countFrame.size.width -= 4;	// clearance on left of capsule
		}
		
		// if the count capsule is not full size there is insufficient room to display it properly.
		// so don't.
		if (countFrame.size.width >= kMinCapsuleWidth) {
			NSBezierPath * bp = [NSBezierPath bezierPathWithRoundRectInRect:countFrame radius:numSize.height / 2];
			[capsuleColor set];
			[bp fill];
			
			// Draw the count in the rounded rectangle we just created.
			NSPoint point = NSMakePoint(NSMidX(countFrame) - numSize.width / 2.0f,  NSMidY(countFrame) - numSize.height / 2.0f );
			[number drawAtPoint:point withAttributes:attributes];
			[attributes release];
		}
		
		cellFrameModified = YES;
	}

	// draw status image
	if (statusImage != nil)
	{
		NSImage *statImage = [self isHighlighted] ? invertedStatusImage : statusImage;
		imageSize = [statImage size];
		NSDivideRect(cellFrame, &imageFrame, &cellFrame, 4 + imageSize.width, NSMaxXEdge);
		
		if (imageFrame.size.width >= imageSize.width) {
			
			//imageFrame.origin.x += kImageOriginXOffset;
			imageFrame.origin.y -= kImageOriginYOffset;
			imageFrame.size = imageSize;
			
			if ([controlView isFlipped]) {
				imageFrame.origin.y += ceilf((cellFrame.size.height + imageFrame.size.height) / 2);
			} else {
				imageFrame.origin.y += ceilf((cellFrame.size.height - imageFrame.size.height) / 2);
			}
			
			[statImage compositeToPoint:imageFrame.origin operation:NSCompositeSourceOver];
		}
		
		cellFrameModified = YES;
	}
	

	
	if (cellFrameModified) {
			
		NSRect newFrame = cellFrame;
		newFrame.origin.x += kTextOriginXOffset;
		newFrame.origin.y += kTextOriginYOffset;
		newFrame.size.height -= kTextHeightAdjust;
		
		// let the super class do its bit and draw the cell text
		[super drawWithFrame:newFrame inView:controlView];
    }
	else
	{
		if ([self isGroupCell])
		{
			// Center the text in the cellFrame, and call super to do the work of actually drawing. 
			CGFloat yOffset = floorf((NSHeight(cellFrame) - [[self attributedStringValue] size].height) / 2);
			cellFrame.origin.y += yOffset;
			cellFrame.size.height -= (kTextOriginYOffset*yOffset);
			[super drawWithFrame:cellFrame inView:controlView];
		}
	}
}

// -------------------------------------------------------------------------------
//	cellSize:
// -------------------------------------------------------------------------------
- (NSSize)cellSize
{
    NSSize cellSize = [super cellSize];
    cellSize.width += (image ? [image size].width : 0) + 3;
    return cellSize;
}

// -------------------------------------------------------------------------------
//	hitTestForEvent:
//
//	In 10.5, we need you to implement this method for blocking drag and drop of a given cell.
//	So NSCell hit testing will determine if a row can be dragged or not.
//
//	NSTableView calls this cell method when starting a drag, if the hit cell returns
//	NSCellHitTrackableArea, the particular row will be tracked instead of dragged.
//
// -------------------------------------------------------------------------------
- (NSUInteger)hitTestForEvent:(NSEvent *)event inRect:(NSRect)cellFrame ofView:(NSView *)controlView
{
	#pragma unused(event)
	#pragma unused(cellFrame)
	#pragma unused(controlView)
	
	// exception being thrown in here somewhere!!
	return NSCellHitTrackableArea;

	
	NSInteger result = NSCellHitContentArea;
	
	NSOutlineView* hostingOutlineView = (NSOutlineView*)[self controlView];
	if (hostingOutlineView)
	{
		NSInteger selectedRow = [hostingOutlineView selectedRow];
		id node = [[hostingOutlineView itemAtRow:selectedRow] representedObject];

		SEL dragSelector = @selector(isDraggable);
		if ([node respondsToSelector:dragSelector]) {
			if (![node performSelector:dragSelector]) {	// is the node isDraggable (i.e. non-file system based objects)
				result = NSCellHitTrackableArea;
			}
		}
	}
		
	return result;
}

/*
 
 JM 23-01-08
 set object value used by bindings machinery
 for NSValueBinding
 
 */
- (void)setObjectValue:(id)object
{
	// set super class object
	if ([object respondsToSelector:@selector(name)]) {
		[super setObjectValue:[object name]];
	} else if ([object respondsToSelector:@selector(value)]) {
		
		// set object value
		if ([[object value] isKindOfClass:[NSString class]]) {
			NSString *stringValue = [object value];
			
			NSUInteger maxLength = 256;
			// we need to limit the length of text in our cell
			if ([stringValue length] > maxLength) {
				stringValue = [stringValue substringToIndex:maxLength];
				stringValue = [NSString stringWithFormat:@"%@ ...", stringValue];
			}
			
			// remove CRLF otherwise text wraps in cell
			stringValue = [stringValue mgs_stringWithOccurrencesOfCrLfRemoved];

			[super setObjectValue:stringValue];
		} else {
			[super setObjectValue:[object value]];
		}
	}
	
	if ([object respondsToSelector:@selector(image)]) {
		[self setImage:[object image]];
	} 
	
	if ([object respondsToSelector:@selector(count)]) {
		[self setCount:[object count]];
	}

	if ([object respondsToSelector:@selector(hasCount)]) {
		[self setHasCount:[object hasCount]]; 
	}
	
	if ([object respondsToSelector:@selector(countColor)]) {
		[self setCountBackgroundColour:[object countColor]];
	}

	if ([object respondsToSelector:@selector(statusImage)]) {
		[self setStatusImage:[object statusImage]];
	} 

	if ([object respondsToSelector:@selector(indentation)]) {
		[self setIndentation:[object indentation]];
	} 
	
	if ([object respondsToSelector:@selector(countAlignment)]) {
		[self setCountAlignment:[object countAlignment]];
	} 
}

// JM
// count
- (void)setCount:(int)value
{
	count = value;
}


// JM
// has count
- (void)setHasCount:(BOOL)value
{
	hasCount = value;
}
- (BOOL)hasCount
{
	return hasCount;
}
@end

