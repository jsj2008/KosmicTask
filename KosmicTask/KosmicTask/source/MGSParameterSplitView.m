//
//  MGSParameterSplitView.m
//  Mother
//
//  Created by Jonathan on 08/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSParameterSplitView.h"
#import "MGSParameterViewController.h"
#import "MGSParameterView.h"

// drag point locations
#define MGSDividerDrag 0
#define MGSBottomThumbDrag 1
#define MGSMiddleThumbDrag 2

/*
 
 resizable parameter interface
 
 */
@interface MGSResizableParameter : NSObject {
	MGSParameterViewController *_parameterViewController;	// view controller of draggable parameter
	NSRect _dragRect;		// drag rect
	NSView *_subViewToResize;	// subview to resize
	NSInteger _dragLocation;
}


@property MGSParameterViewController *parameterViewController;
@property NSRect dragRect;
@property NSView *subViewToResize;
@property NSInteger dragLocation;
@end

/*
 
 draggable parameter implementation
 
 */
@implementation MGSResizableParameter
@synthesize parameterViewController = _parameterViewController;
@synthesize dragRect = _dragRect;
@synthesize subViewToResize = _subViewToResize;
@synthesize dragLocation = _dragLocation;

/*
 
 init
 
 */
- (id)init
{
	if ([super init]) {
		_parameterViewController = nil;
		_dragRect = NSZeroRect;
		_subViewToResize = nil;
		_dragLocation = MGSDividerDrag;
	}
	return self;
}
@end

@interface MGSParameterSplitView (Private)
- (void) addDraggableParameterController:(MGSParameterViewController *)parameterViewController withRect:(NSRect)rect atLocation:(NSInteger)dragLoc;
@end

MGSResizableParameter *resizingParameter = nil;

@implementation MGSParameterSplitView

@synthesize isDragging = _isDragging;

/*
 
 init with code
 
 The Object Loading Process
 When you use the methods of NSNib or NSBundle to load and instantiate the objects in a nib file, Cocoa does the following:
 
 Cocoa loads the contents of the nib file into memory:
 The raw data for the nib object graph is loaded into memory but is not unarchived.
 Any custom image resources associated with the nib file are loaded and added to the Cocoa image cache; see “About Image and Sound Resources.”
 Any custom sound resources associated with the nib file are loaded and added to the Cocoa sound cache; see “About Image and Sound Resources.”
 It unarchives the nib object graph data.
 Standard Interface Builder objects (and custom subclasses of those objects) receive an initWithCoder: message.
 Standard objects are the objects you drag into a nib file from the Interface Builder palettes. Even if you change the class of such an object,
 Interface Builder encodes the standard object into the nib file and then tells the archiver to swap in your custom class when the object is unarchived.
 
 Custom subclasses of NSView receive an initWithFrame: message.
 This case applies only when you use a custom view object in Interface Builder. When it encounters a custom view, Interface Builder encodes a 
 special NSCustomView object into your nib file. The custom view object includes the information it needs to build the real view subclass you specified. 
 At load time, the NSCustomView object sends an alloc and initWithFrame: message to the real view class and then swaps the resulting 
 view object in for itself. The net effect is that the real view object handles subsequent interactions during the nib-loading process.
 
 Non-view objects in the archive receive an init message.
 It reestablishes all connections (actions, outlets, and bindings) between objects in the nib file. This includes connections to File’s 
 Owner and other proxy objects.
 It sends an awakeFromNib message to all objects that define the matching selector.
 It displays any windows whose “Visible at launch time” attribute was enabled in Interface Builder.
 During the reconnection process, the nib-loading code reconnects any outlets, actions, and bindings you created in Interface Builder. 
 When reestablishing outlet connections, Cocoa tries to do so using the object’s own methods first. For each outlet, 
 Cocoa looks for a method of the form setOutletName: and calls it if such a method is present. If it cannot find such a method, 
 Cocoa searches the object for an instance variable with the corresponding outlet name and tries to set the value directly. 
 If the instance variable cannot be found, no connection is created.
 
 For actions, Cocoa uses the source object’s setTarget: and setAction: methods to establish the connection to the target object. 
 If the target object does not respond to the action method, no connection is created. A connection is still created if the target 
 object is nil; however, this behavior is used to support connections that occur through the responder chain. Such connections have
 an action and a dynamic target object.
 
 Cocoa sends the awakeFromNib message to every object in the nib file that defines the corresponding selector. This applies not
 only to the custom objects you added to the nib file but also to proxy objects such as File’s Owner. The order in which Cocoa calls
 the awakeFromNib methods of objects in the nib file is not guaranteed, although Cocoa tries to call the awakeFromNib method of File’s Owner last. 
 If you do need to perform some final initialization of your nib file objects, it is best to do so after your nib-loading calls return.
 
 
 */
- (id)initWithCoder:(NSCoder *)decoder
{
	if ([super initWithCoder:decoder]) {
		_isDragging = NO;
		_resizableParameters = [NSMutableArray arrayWithCapacity:2];
	}
	return self;
}

/*
 
 divider thickness
 
 */
- (CGFloat)dividerThickness
{
	return 2;
}

/*
 
 draw divider in rect
 
 */
- (void)drawDividerInRect:(NSRect)aRect
{
	#pragma unused(aRect)
	
	// we want the divider to be empty so don't draw a thing
}

/*
 
 resize sub view to new size
 
 */
/*
- (void)subView:(NSView *)view resizeViewWithNewSize:(NSSize)newSize
{
	NSRect viewFrame = [view frame];
	//CGFloat deltaHeight = newSize.height - viewFrame.size.height;
	
	// resize view
	viewFrame.size = newSize;
	[view setFrame:viewFrame];
	[view setNeedsDisplay:YES];
	
	// now auto resize the splitview height
	// it will call the delegate with - (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize:(NSSize)oldSize
	// giving us an opportunity to resize our view
	//[self autoSizeHeight];
}
*/

/*
 
 mouse down
 
 NSResponder override 
 
 */
- (void)mouseDown:(NSEvent *)theEvent
{
	_isDragging = NO;
	resizingParameter = nil;
	_restrictSubViewHeight = NO; 
	[[NSCursor currentCursor] push];

	NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];	// convert to view co-ordinates
	
	// loop through draggable parameters looking for hit	
	for (MGSResizableParameter *resizableParameter in _resizableParameters) {
		 
		// hit test in drag rect
		if ([self mouse:mouseLoc inRect:[resizableParameter dragRect]]) {

			// cache subview to be dragged
			resizingParameter = resizableParameter;
			
			// restrict to view controller max and min heights
			_restrictSubViewHeight = YES;

			// cache location
			_prevMouseLoc = mouseLoc;
			_isDragging = YES;

		}
	}
}

/*
 
 mouse dragged
 
 NSResponder override 
 
 */

- (void)mouseDragged:(NSEvent *)theEvent
{
	// need a view to drag
	if (!resizingParameter) return;
	
	//NSLog(@"mouse dragged");
	NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];	// convert to view co-ordinates
	//NSSize size = [self frame].size;

	MGSParameterViewController *viewController = [resizingParameter parameterViewController];
	
	// get the subview directly above the splitter and size it to
	// accomodate the change in the overall view size	
	NSSize subViewSize = [[viewController view] frame].size;

	// vertical mouse movement
	CGFloat yDelta = mouseLoc.y - _prevMouseLoc.y;

	// sub view new height
	CGFloat subViewHeight = subViewSize.height;
	CGFloat newSubViewHeight = subViewHeight + yDelta;
	
	// restrict height if reqd
	if (_restrictSubViewHeight) {
		if (newSubViewHeight < [viewController minHeight]) {
			if (subViewHeight > [viewController minHeight]) {
				newSubViewHeight = [viewController minHeight];	// make min height
			} else {
				[[NSCursor resizeDownCursor] set];
				return;
			}
		}
		else if (newSubViewHeight > [viewController maxHeight]) {
			if (subViewHeight < [viewController maxHeight]) {
				newSubViewHeight = [viewController maxHeight];	// make max height
			} else {
				[[NSCursor resizeUpCursor] set];
				return;
			}
		}
	}
	
	// recalc ydelta and mouseLoc to account of cases
	// where we have restriced the subView to max or min height
	// even though mouse has moved beyond the max/min
	yDelta = newSubViewHeight - subViewHeight;
	
	// 
	// check that the proposed size changed is acceptable
	// to the paramter views subviews.
	//
	if (MGSParameterModeEdit == viewController.mode) {
		switch ([resizingParameter dragLocation]) {
			case MGSDividerDrag:
			case MGSMiddleThumbDrag:
				// check if can modify ydelta as intended
				yDelta = [viewController canModifyMiddleViewHeightBy:yDelta];
				break;
				
			case MGSBottomThumbDrag:
				// check if can modify ydelta as intended
				yDelta = [viewController canModifyBottomViewHeightBy:yDelta];
				break;
				
			default:
				NSAssert(NO, @"invalid drag location");
				break;
		}
	} else if (MGSParameterModeInput == viewController.mode) {
		// use default sizing behaviour
	} else {
		NSAssert(NO, @"invalid mode");
	}
	
	// if delta is zero then parameter subview cannot be resized
	if (0 == (NSInteger)yDelta) {
		[[viewController resizeCursor] set];
		return;
	}

	// default drag cursor
	[[NSCursor resizeUpDownCursor] set];
		
	// recalc ydelta and mouseLoc to account of cases
	// where we have restriced the subView to max or min height
	// even though mouse has moved beyond the max/min
	newSubViewHeight = yDelta + subViewHeight;
	
	// check
	mouseLoc.y = yDelta + _prevMouseLoc.y;
	
	// modify parameter view height
	subViewSize.height = newSubViewHeight;
	[[viewController view] setFrameSize:subViewSize];

	// depending on how the parameter view is dragged may need to resize
	// subviews
	// determine which view to resize during drag	
	if (MGSParameterModeEdit == viewController.mode) {
		switch ([resizingParameter dragLocation]) {
			case MGSDividerDrag:
			case MGSMiddleThumbDrag:
				// default operation, the parameters subviews will resize
				// themselves correctly.
				// when dragged the bottom view stays fixed and the middle view resizes.
				break;
				
			case MGSBottomThumbDrag:
				// want to leave middle view at previous size and resize bottom view
				[viewController modifyBottomViewHeightBy:yDelta];
				break;
				
			default:
				NSAssert(NO, @"invalid drag location");
				break;
		}
	} else if (MGSParameterModeInput == viewController.mode) {
		// use default sizing behaviour
	} else {
		NSAssert(NO, @"invalid mode");
	}
	
	/*
	// search from bottom to top of splitview
	// and adjust subview origins accordingly
	// (remember that NSSplitView uses flipped coordinates)
	for (int i = [[self subviews] count] -1; i >= 0; i--) {
		NSView *subView = [[self subviews] objectAtIndex:i];

		if (subView == [viewController view]) {
			break;
		}
		
		// offset view origin
		NSPoint origin = [subView frame].origin;
		origin.y += yDelta;
		[subView setFrameOrigin:origin];
		[subView setNeedsDisplay:YES];
	}
	*/
	
	// for cursor flashing during drag see
	// http://www.cocoadev.com/index.pl?CursorFlashingProblems
	
	// cache location
	_prevMouseLoc = mouseLoc;
}

/*
 
 mouse up
 
 NSResponder override 
 
 */

- (void)mouseUp:(NSEvent *)theEvent
{
	#pragma unused(theEvent)
	
	//NSLog(@"mouse up");
	_isDragging = NO;
	resizingParameter = nil;
	[NSCursor pop];
}

/*
 
 reset the cursor rects
 
 the super implementation creates a cursor rect for each divider
 
 */
- (void)resetCursorRects
{
	NSView *subView;
	NSRect cursorRect = NSMakeRect(0, 0, [self frame].size.width, [self dividerThickness]);
	NSRect convertedRect, thumbRect;
	
	[_resizableParameters removeAllObjects];
	
	// search down through subviews
	for (NSUInteger i = 0; i < [[self subviews] count]; i++) {
		subView = [[self subviews] objectAtIndex:i];
			
		// get max and min size for view from controller
		if ([subView isKindOfClass:[MGSParameterView class]]) {
			MGSParameterViewController *viewController = [(MGSParameterView *)subView delegate];
						
			// may not be able to drag the view
			if ([viewController canDragHeight]) {
				
				// add divider rect
				NSRect subViewFrame = [subView frame];
				cursorRect.origin.y = subViewFrame.origin.y + subViewFrame.size.height;
				[self addDraggableParameterController:viewController withRect:cursorRect atLocation:MGSDividerDrag];
				
				// add drag thumb rect if defined
				thumbRect = [viewController dragThumbRect];
				if (thumbRect.size.width > 0  && thumbRect.size.height > 0) {
					convertedRect = [self convertRect:thumbRect fromView:[viewController view]];
					[self addDraggableParameterController:viewController withRect:convertedRect atLocation:MGSBottomThumbDrag];
				}

				// add middle view drag thumb rect if defined
				thumbRect = [viewController middleDragThumbRect];
				if (thumbRect.size.width > 0  && thumbRect.size.height > 0) {
					convertedRect = [self convertRect:thumbRect fromView:[viewController view]];
					[self addDraggableParameterController:viewController withRect:convertedRect atLocation:MGSMiddleThumbDrag];
				}
				
			}

		} 

	}
	
}
@end

@implementation MGSParameterSplitView (Private)

/*
 
 add draggable parameter view controller with drag rect
 
 */
- (void) addDraggableParameterController:(MGSParameterViewController *)parameterViewController withRect:(NSRect)rect 
		atLocation:(NSInteger)dragLoc
{
	// add draggable rect to view cursor rects
	[self addCursorRect:rect cursor:[NSCursor resizeUpDownCursor]];

	// add draggable parameter
	MGSResizableParameter *draggableParameter = [[MGSResizableParameter alloc] init];
	draggableParameter.parameterViewController = parameterViewController;
	draggableParameter.dragRect = rect;
	draggableParameter.dragLocation = dragLoc;
	
	// determine which view to resize during drag	
	if (MGSParameterModeEdit == parameterViewController.mode) {
		switch (dragLoc) {
			case MGSDividerDrag:
			case MGSBottomThumbDrag:
				break;
				
			case MGSMiddleThumbDrag:
				break;
				
			default:
				NSAssert(NO, @"invalid drag location");
				break;
		}
	} else if (MGSParameterModeInput == parameterViewController.mode) {
	} else {
		NSAssert(NO, @"invalid mode");
	}

	[_resizableParameters addObject:draggableParameter];
		
}
@end
