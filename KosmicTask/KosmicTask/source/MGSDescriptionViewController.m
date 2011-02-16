//
//  MGSDescriptionViewController.m
//  Mother
//
//  Created by Jonathan on 13/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSDescriptionViewController.h"
#import "MGSScriptParameter.h"
#import "NSTextField_Mugginsoft.h"

#define DYNAMIC_TOP_MARGIN 10
#define DYNAMIC_BOTTOM_MARGIN 5

@interface MGSDescriptionViewController (Private)
- (void)layoutViewForMode;
- (void)setDisclosureButtonIsHidden:(BOOL)isHidden;
- (void)resizeHasOccurred:(NSSize)oldSize;
- (void)updateDynamicDescription;
- (NSSize)descriptionTitleLineSize;
@end

@implementation MGSDescriptionViewController

@synthesize mode = _mode;
@synthesize delegate = _delegate;

/*
 
 init with mode
 
 this is the designated initialiser
 
 */
-(id)initWithMode:(MGSParameterMode)mode
{
	if ([super initWithNibName:@"DescriptionView" bundle:nil]) {
		_mode = mode;
		_layoutHasOccurred = NO;
	}
	return self;
}
/*
 
 init
 
 */
-(id)init
{
	return [self initWithMode: MGSParameterModeInput];
}
/*
 
 awake from nib
 
 */
- (void)awakeFromNib
{
	//_initialViewFrame = [[self view] frame];
	[self layoutViewForMode];
}

/*
 
 set represented object
 
 */
- (void)setRepresentedObject:(id)object
{
	
	if ([self representedObject]) {
		[description unbind:NSValueBinding];
		[self setRepresentedObject: nil];
	}
	
	//
	// set up the bindings
	// This can be done in IB of course but at least here I can see what is going on
	// and change the biding if needs be.
	// And there is less cause of a stray mouse click causing havoc.
	// But see above fro nib loading effects
	//
	[super setRepresentedObject: object];
	
	// bind controls to represented object depending on the parameter mode
	//
	// input mode
	// user is inputting parameter data
	//
	if (MGSParameterModeInput == _mode) {
		[description bind:NSValueBinding toObject:self withKeyPath:@"representedObject.description" options:nil];
		[self updateDynamicDescription];
	} else if (MGSParameterModeEdit == _mode) {
		//
		// edit mode
		// user is defining parameter
		//
		[description bind:NSValueBinding toObject:self withKeyPath:@"representedObject.description" options:nil];
	} else {
		NSAssert(NO, @"invalid mode");
	}
	

}

/*
 
 disclosure buttton click
 
 */
- (IBAction)disclosureButtonClick:(id)sender
{
	#pragma unused(sender)
	
	[self updateDynamicDescription];
}

/*
 
 toggle description disclosure
 
 */
- (void)toggleDescriptionDisclosure
{
	if (![descriptionDisclosureButton isHidden]) {
		[descriptionDisclosureButton setState:![descriptionDisclosureButton state]];
		[self disclosureButtonClick:descriptionDisclosureButton];
	}
}

/*
 
 initial layout size
 
 */
- (NSSize)initialLayoutSize
{
	NSSize size =  [self view].frame.size;
	
	//
	// input mode
	//
	if (MGSParameterModeInput == _mode) {
		size.height = [self descriptionTitleLineSize].height + DYNAMIC_TOP_MARGIN + DYNAMIC_BOTTOM_MARGIN;
		// edit mode	
	} else if (MGSParameterModeEdit == _mode) {
		
		// view frame size will remain as is
	} else {
		NSAssert(NO, @"invalid parameter mode");
	}
	
	return size;
}

// this will be called by the binding machinery to
// modify the model data
- (void)setValue:(id)value forKeyPath:(NSString *)keyPath
{
	[super setValue:value forKeyPath:keyPath];
	[[[self view] window] setDocumentEdited:YES];
}

@end

@implementation MGSDescriptionViewController (Private)

/*
 
 get text line size of the description title
 
 */
- (NSSize)descriptionTitleLineSize
{
	return [@"A" boundingRectWithSize:[descriptionTitle frame].size options:NSStringDrawingUsesLineFragmentOrigin| NSStringDrawingDisableScreenFontSubstitution attributes:nil].size;

}
/*
 
 update the dynamic description
 
 */
- (void)updateDynamicDescription
{
	// only valid for input mode
	NSAssert(MGSParameterModeInput == _mode, @"dynamic description requires input mode");
	
	// if no script parameter then description will be nil leading to an NSException
	NSString *text = @"???";
	if ([self representedObject]) {
		text = [[self representedObject] description];
	}
	
	// get size of text and size of one line of text
	NSSize textSize = [text boundingRectWithSize:[descriptionTitle frame].size options:NSStringDrawingUsesLineFragmentOrigin| NSStringDrawingDisableScreenFontSubstitution attributes:nil].size;
	NSSize lineSize = [self descriptionTitleLineSize];

	// does text fit on one line?
	BOOL textOnOneLine = ((NSInteger)lineSize.height == (NSInteger)textSize.height) ? YES : NO;
	
	// set disclosure button visibility
	// see below for vertically explanding text field
	// http://www.cocoadev.com/index.pl?IFVerticallyExpandingTextfield
	[self setDisclosureButtonIsHidden:textOnOneLine];
	[descriptionTitle setStringValue:text];
	
	NSSize viewFrameSize = [self view].frame.size;
	NSSize viewOldSize = viewFrameSize;
	NSRect titleFrame = NSZeroRect;
	
	// if text does not all fit on one line
	if (!textOnOneLine && NSOnState == [descriptionDisclosureButton state]) {
		
		// configure the cell
		[[descriptionTitle cell] setScrollable:YES];
		[[descriptionTitle cell] setWraps:YES]; 
		[[descriptionTitle cell] setLineBreakMode:NSLineBreakByWordWrapping];	// wrap words
		
		// show all text
		// increase height of title
		// size vertically to display all text
		CGFloat newHeight = [descriptionTitle verticalHeightToFit];	
		CGFloat yDelta = (newHeight - lineSize.height);
		
		// resize the view
		viewFrameSize.height += yDelta;
		[[self view] setFrameSize:viewFrameSize];
		[[self view] setNeedsDisplay:YES];
		
		// resize the title
		titleFrame = [descriptionTitle frame];
		titleFrame.size.height += yDelta;
		titleFrame.origin.y -= yDelta;
	} else {
		// show single line of text.
		// if more than one line of text exists then the disclosure rectangle
		// will be visible
		
		// configure the cell		
		[[descriptionTitle cell] setScrollable:NO];
		[[descriptionTitle cell] setWraps:NO]; 
		[[descriptionTitle cell] setLineBreakMode:NSLineBreakByTruncatingTail];	// truncate tail with ellipsis
		
		// resize view to show one line title only
		viewFrameSize.height = lineSize.height + DYNAMIC_BOTTOM_MARGIN + DYNAMIC_TOP_MARGIN;
		[[self view] setFrameSize:viewFrameSize];
		[[self view] setNeedsDisplay:YES];
		
		// position title frame at bottom of view
		titleFrame = [descriptionTitle frame];
		titleFrame.size.height = lineSize.height;
		titleFrame.origin.y = DYNAMIC_BOTTOM_MARGIN;
	}
	
	[descriptionTitle setFrame:titleFrame];
	[descriptionTitle setNeedsDisplay:YES];

	// position the image frame
	NSRect imageFrame = [descriptionImageView frame];
	imageFrame.origin.y = titleFrame.origin.y + titleFrame.size.height - imageFrame.size.height;
	[descriptionImageView setFrame:imageFrame];
	
	// position the disclosure triangle
	NSRect disclosureRect = [descriptionDisclosureButton  frame];
	disclosureRect.origin.y = imageFrame.origin.y + imageFrame.size.height /2 - disclosureRect.size.height /2;
	[descriptionDisclosureButton setFrame:disclosureRect];
	
	// tell delegate about resize
	[self resizeHasOccurred:viewOldSize];		
	
}

/*
 
 layout view for mode

 
 this message should only be sent once as it modfies the view from its
 initial nib state
 
 */
- (void)layoutViewForMode
{
	
	NSAssert(NO == _layoutHasOccurred, @"description view layout has already occurred");
	
	//
	// input mode
	//
	if (MGSParameterModeInput == _mode) {
		
		// we will use dynamic description
		[descriptionScrollView setHidden:YES];
		
		// edit mode	
	} else if (MGSParameterModeEdit == _mode) {
		
		// no need of the disclosure button whilst editing
		[self setDisclosureButtonIsHidden:YES];
		
		// don't want the info image visible
		[descriptionImageView setHidden:YES];
		
		// reposition title to lhs
		NSPoint descOrigin = [description frame].origin;
		NSPoint titleOrigin = [descriptionTitle frame].origin;
		titleOrigin.x = descOrigin.x;
		[descriptionTitle setFrameOrigin:titleOrigin];
		
	} else {
		NSAssert(NO, @"invalid parameter mode");
	}
	
	_layoutHasOccurred = YES;;
}

/*
 
 set disclosure button is hidden
 
 */
- (void)setDisclosureButtonIsHidden:(BOOL)isHidden
{
	NSPoint disclosureOrigin = [descriptionDisclosureButton frame].origin;
	NSPoint titleOrigin = [descriptionTitle frame].origin;
	
	// reveal
	if (!isHidden) {
		// reveal the disclosure triangle
		[descriptionDisclosureButton setHidden:NO];
		
		// position description title
		titleOrigin.x = disclosureOrigin.x + [descriptionDisclosureButton frame].size.width;
		[descriptionTitle setFrameOrigin:titleOrigin];
		[descriptionTitle setNeedsDisplay];

	} else  {
		
		// hide disclosure triangle
		[descriptionDisclosureButton setHidden:YES];
		
		// position description title
		titleOrigin.x = disclosureOrigin.x;
		[descriptionTitle setFrameOrigin:titleOrigin];
		[descriptionTitle setNeedsDisplay];
	} 
}

/*
 
 the control has resized itself
 
 */
- (void)resizeHasOccurred:(NSSize)oldSize
{
	if (_delegate && [_delegate respondsToSelector:@selector(descriptionViewDidResize:oldSize:)]) {
		[_delegate descriptionViewDidResize:self oldSize:oldSize];
	}
}

@end
