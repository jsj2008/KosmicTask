//
//  MGSImageBrowserView.m
//  Mother
//
//  Created by Jonathan on 06/10/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSImageBrowserView.h"
#import "MGSImageBrowserViewController.h"
#import "MGSResultViewController.h"

// class interface extension
@interface MGSImageBrowserView()
- (BOOL)eventExtendsSelection:(NSEvent *)theEvent;
@end

@implementation MGSImageBrowserView


/*
 
 mouse down
 
 */
- (void)mouseDown:(NSEvent *)theEvent
{
	leftMouseExtendedSelection = [self eventExtendsSelection:theEvent];
	[super mouseDown:theEvent];
}

/*
 
 event extends selection
 
 */
- (BOOL)eventExtendsSelection:(NSEvent *)theEvent
{
	NSUInteger flags = [theEvent modifierFlags];
	
	// command or shift to extend selection
	return ((flags & (NSCommandKeyMask | NSShiftKeyMask)) > 0)  ? YES : NO;
}

/*
 
 right mouse down
 
 */
- (void)rightMouseDown:(NSEvent *)theEvent
{
	// select item with right click while maintaining selection
	NSInteger itemIndex = [self indexOfItemAtPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil]];
	if (itemIndex != NSNotFound) {
		
		// command or shift to extend selection
		BOOL extendSelection = [self eventExtendsSelection:theEvent];
		
		// finder works this way.
		// if were extending the selection with left mouse clicks then a right click always continues
		// to extend the selection
		if (leftMouseExtendedSelection) {
			extendSelection = YES;
		}
		
		// check we are selecting a new item
		if (![[self selectionIndexes] containsIndex:itemIndex]) {
			[self setSelectionIndexes:[NSIndexSet indexSetWithIndex:itemIndex] byExtendingSelection:extendSelection];
		}
	}
	[NSMenu popUpContextMenu:[self menu] withEvent:theEvent forView:self];
}
/*
 
 mouse up
 
 */
- (void)mouseUp:(NSEvent *)theEvent
{
	
	if ([theEvent clickCount] <= 1) {
		[super mouseUp:theEvent];
	} else {
		// default double click op is to open image with default app.
		// this is not desirable as the file is in the cache and has not yet been saved to a folder of the user's choice
		
		if([self.delegate respondsToSelector:@selector(quicklook:)]) {
			[self.delegate quicklook:self];
		}
	}
}

/*
 
 save document
 
 */
/*
- (IBAction)saveDocument:(id)sender
{
	#pragma unused(sender)
	
	if([self.delegate respondsToSelector:@selector(save:)]) {
		[(MGSImageBrowserViewController *)self.delegate save:self];
	}
}
*/
/*
 
 validate menu item
 
 */
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	SEL theAction = [menuItem action];
	
	// quicklook
	if (theAction == @selector(quicklook:)) {
		
		// if no items then invalidate
		if ([[self delegate] numberOfItemsInImageBrowser:self] == 0) {
			return NO;
		}
		
		// finder displays Quick Look <filename> and Quick Look <2 items>
		NSString *menuTitle = NSLocalizedString(@"Quick Look", @"Quick look menu item");
		NSString *suffix = nil;
		
		NSIndexSet *indexSet = [self selectionIndexes];
		switch ([indexSet count]) {
				
			// if none selected then quicklook just the first
			case 0:
				suffix = NSLocalizedString(@" First Result File", @"Quick look menu result suffix - first result file");
				break;
				
			case 1: {;
				id browserImage = [[self delegate] imageBrowser:self itemAtIndex:[indexSet firstIndex]];
				suffix = [NSString stringWithFormat:NSLocalizedString(@" \"%@\"", @"Quick look menu result suffix - named result"), [browserImage imageTitle]];
				break;
				
			}
			default:
				suffix = [NSString stringWithFormat:NSLocalizedString(@" %i Result Files", @"Quick look menu result suffix - n results"), [indexSet count]];
				break;
		}
		
		[menuItem setTitle:	[menuTitle stringByAppendingString:suffix]];
		return YES;
	}
	
	// save result
	else if (theAction == @selector(saveResult:)) {

		// if no items then invalidate
		if ([[self delegate] numberOfItemsInImageBrowser:self] == 0) {
			return NO;
		}
		
		// display like quicklook
		NSString *menuTitle = NSLocalizedString(@"Save", @"Save menu item");
		NSString *suffix = nil;
		
		NSIndexSet *indexSet = [self selectionIndexes];
		switch ([indexSet count]) {
				
			// if none selected then save all
			case 0:
				suffix = NSLocalizedString(@" Result Files As...", @"Save menu item suffix - save results");
				break;
				
			case 1: {;
				id browserImage = [[self delegate] imageBrowser:self itemAtIndex:[indexSet firstIndex]];
				suffix = [NSString stringWithFormat:NSLocalizedString(@" \"%@\" As...", @"Save result item suffix - named result"), [browserImage imageTitle]];
				break;
				
			}
			default:
				suffix = [NSString stringWithFormat:NSLocalizedString(@" %i Result Files As...", @"save result menu item suffix - n items"), [indexSet count]];
				break;
		}
		
		[menuItem setTitle:	[menuTitle stringByAppendingString:suffix]];
		return YES;
	}
	
	return YES;
}

/*
 
 quick look
 
 */
- (IBAction)quicklook:(id)sender
{
	#pragma unused(sender)
	
	if([self.delegate respondsToSelector:@selector(quicklook:)]) {
		[(MGSImageBrowserViewController *)self.delegate quicklook:self];
	}
}

/*
 
 view did move to window
 
 */
- (void)viewDidMoveToWindow
{
	if (self.delegate && [self.delegate respondsToSelector:@selector(view:didMoveToWindow:)]) {
		[self.delegate view:self didMoveToWindow:[self window]];
	}
}

@end
