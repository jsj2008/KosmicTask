//
//  MGSRequestTabScrollView.m
//  Mother
//
//  Created by Jonathan on 28/10/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSRequestTabScrollView.h"
#import "MGSRequestViewController.h"

@implementation MGSRequestTabScrollView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

/*
 
 resize subviews with old size
 
 */
- (void)resizeSubviewsWithOldSize:(NSSize)oldBoundsSize
{
	if ([delegate respondsToSelector:@selector(view:willResizeSubviewsWithOldSize:)]) {
		[delegate view:self willResizeSubviewsWithOldSize:oldBoundsSize];
	}
	
	[super resizeSubviewsWithOldSize:oldBoundsSize];
	
	if ([delegate respondsToSelector:@selector(view:didResizeSubviewsWithOldSize:)]) {
		[delegate view:self didResizeSubviewsWithOldSize:oldBoundsSize];
	}
}

/*
 
 set appopriate scollview document width with old size
 
 */
- (void)sizeDocumentWidthForRequestViewController:(MGSRequestViewController *)requestViewController withOldSize:(NSSize)oldBoundsSize 
{
	if (!requestViewController) return;
	
	NSSize boundsSize = [self bounds].size;
	NSSize sizeDelta = NSMakeSize(boundsSize.width - oldBoundsSize.width, boundsSize.height - oldBoundsSize.height);
	
	// if should not resize then only autosize height
	if (![requestViewController shouldResizeWithSizeDelta:sizeDelta]) {
		
		// our request view is the document view
		// our document no longer auto resizes its width
		if ([[self documentView] autoresizingMask] != NSViewHeightSizable) {
			
			// make sure that document is at minimum width
			NSSize sizeDocument = [[self documentView] frame].size;
			sizeDocument.width = [requestViewController minViewWidth];
			
			[[self documentView] setAutoresizingMask:NSViewHeightSizable];
			[[self documentView] setFrameSize:sizeDocument];
			[[self documentView] setNeedsDisplay:YES];
			
		}
	} 
	
}

/*
 
 reset appopriate scollview document width with old size
 
 */
- (void)resetDocumentWidthForRequestViewController:(MGSRequestViewController *)requestViewController withOldSize:(NSSize)oldBoundsSize 
{
	#pragma unused(oldBoundsSize)
	
	if (!requestViewController) return;
	
	// if resizing only height then check if need to reset width autosizing
	if ([[self documentView] autoresizingMask] == NSViewHeightSizable) {
		
		// if the content is wider than then document then size the document to the content
		NSSize documentSize = [[self documentView] frame].size;
		NSSize contentSize = [self contentSize];
		if (contentSize.width >= documentSize.width) {
			
			// make our document view fit our content
			[[self documentView] setFrameSize: NSMakeSize(contentSize.width, documentSize.height)];
			[[self documentView] setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
		}
		
	}
	
}	


@end
