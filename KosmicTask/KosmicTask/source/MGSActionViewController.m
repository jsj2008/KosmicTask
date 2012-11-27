//
//  MGSActionViewController.m
//  Mother
//
//  Created by Jonathan on 06/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSActionViewController.h"
#import "MGSImageAndTextCell.h"
#import "MGSTaskSpecifier.h"
#import "MGSScript.h"
#import "MGSScriptParameterManager.h"
#import "MGSActionView.h"
#import "NSImage+Negative.h"
#import "MGSTextPanelViewController.h"
#import "MGSActionInputFooterViewController.h"
#import "MGSOutputRequestViewCOntroller.h"
#import "MLog.h"
#import "NSView_Mugginsoft.h"
#import "MGSImageManager.h"

// class extension
@interface MGSActionViewController ()
- (void)setParameterCountLabelColour:(NSColor *)color;
@end

@interface MGSActionViewController (Private)
@end

@implementation MGSActionViewController 

@synthesize action = _task;
@synthesize invertedLeftBannerImage = _invertedLeftBannerImage;

/*
 
 init with mode
 
 */
-(id)initWithMode:(MGSParameterMode)mode 
{
	if ([super initWithNibName:@"ActionView" bundle:nil]) {
		_mode = mode;
		self.bannerLeft = @"";
		self.bannerRight = @"";
		_invertedLeftBannerImage = NO;
	}
	return self;
}

/*
 
 init
 
 */

- (id)init
{
	return [self initWithMode: MGSParameterModeInput];
}

/*
 
 awake from nib
 
 */
- (void)awakeFromNib
{
	[super awakeFromNib];

	// input mode
	if (_mode == MGSParameterModeInput) {
		// create description view controller with appropriate mode
		_descriptionViewController = [[MGSTextPanelViewController alloc] init];
		//[_descriptionViewController setDelegate:self];
		[_descriptionViewController view];	// load the view

		// top view is nil
		
		// replace the middle view
		[[_descriptionViewController view] setAutoresizingMask:[self.middleView autoresizingMask]];
		[[self view] replaceSubview:self.middleView withViewFrameAsOld:[_descriptionViewController view]];
		self.middleView = [_descriptionViewController view];
		
		// create footer view
		_actionInputFooterViewController = [[MGSActionInputFooterViewController alloc] init];
		[_actionInputFooterViewController setDelegate:self];
		[_actionInputFooterViewController view];	// load the view

		// replace the bottom view
		[[self view] replaceSubview:self.bottomView withViewFrameAsOld:[_actionInputFooterViewController view]];
		self.bottomView = [_actionInputFooterViewController view];
		
		[self actionView].drawFooter = YES;
		[self updateFooterPosition];
		[self setCanDragHeight:NO];
		[self setCanDragMiddleView:NO];
	} else {
		
		// edit mode configured externally
		[self setCanDragHeight:NO];
		[self setCanDragMiddleView:NO];
	}
	
    _parameterCountLabelColourDisabled = [MGSImageAndTextCell countColorMidGrey];
    _parameterCountLabelColourEnabled = [MGSImageAndTextCell countColorDarkBlue];
	[self setParameterCountLabelColour:_parameterCountLabelColourDisabled];
    
	// needed to ensure correct view repositioning 
	[self cacheMiddleViewTopYOffset];
}

/*
 
 - setParameterCountLabelColour:
 
 */
- (void)setParameterCountLabelColour:(NSColor *)color
{
    [[self.bannerRightLabel cell] setBackgroundColor:color];
}
/*
 
 - setResetEnabled
 
 */
- (void)setResetEnabled:(BOOL)newValue
{
	[_actionInputFooterViewController setResetEnabled:newValue];
}
/*
 
 is reset enabled
 
 */
- (BOOL)isResetEnabled {
	return [_actionInputFooterViewController isResetEnabled];
}
/*
 
 reset to default value
 
 */
- (void)resetToDefaultValue 
{
	if (self.delegate && [self.delegate respondsToSelector:_cmd]) {
		[self.delegate performSelector:_cmd];
	}
}

/*
 
 set highlighted
 
 */
- (void)setHighlighted:(BOOL)value
{
	_descriptionViewController.highlighted = value;
}
/*
 
 set action
 
 */
- (void)setAction:(MGSTaskSpecifier *)task
{
	if (_task.script) {
		@try {
			[_task removeObserver:self forKeyPath:@"runStatus"];
		} 
		@catch (NSException *e) {
			MLog(RELEASELOG, @"%@", [e reason]);
		}
	}
	
	_task = task;
	[self.bannerLeftLabel bind:NSValueBinding toObject:self withKeyPath:@"action.script.name" options:nil];
	[self updateParameterCountDisplay];

	MGSScript *script = [_task script];

	if (_mode == MGSParameterModeInput) {
		//MGSScriptParameterHandler *parameterHandler = [script parameterHandler];
		NSString *description = [script description];
        description = [description stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (!description || [description length] == 0) {
            description = [script name]; 
        }
		[_descriptionViewController setStringValue:description];
		_actionInputFooterViewController.actionSpecifier = _task;
	}
	
	// left image shows script bundle status
	[leftBannerImageView setImage:[script isBundled] ? [NSImage imageNamed:@"NSActionTemplate"]:[NSImage imageNamed:@"NSUserTemplate"] ];

	// right image enabled status shows if script representation can
	// be executed. initially a non executable preview representation will
	// be displayed while an executable representation is retrieved from the server
	BOOL executableRepresentation = [script canConformToRepresentation:MGSScriptRepresentationExecute];
	[rightBannerImageView setEnabled:executableRepresentation];
	
	if (_task.script) {
		[_task addObserver:self forKeyPath:@"runStatus" options:NSKeyValueObservingOptionNew context:MGSRunStatusContext];
	}
}

#pragma mark -
#pragma mark KVO
/*
 
 observe value for key path
 
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	#pragma unused(keyPath)
	#pragma unused(object)
	#pragma unused(change)
	
	// action run status changed
	if (context == MGSRunStatusContext) {
		[_descriptionViewController setActivity:_task.activity];
	}
}
/*
 
 update the banner
 
 */
- (void)updateParameterCountDisplay
{
	MGSScript *script = [_task script];
	MGSScriptParameterManager *parameterHandler = [script parameterHandler];

	// number of parameters
	NSInteger parameterCount = [parameterHandler count];
	
	// right label is parameter count
	[self.bannerRightLabel setStringValue:[NSString stringWithFormat:@"%ld", (long)[parameterHandler count]]];
	
    // if we have an executable representation then we can execure the script
    BOOL executableRepresentation = [script canConformToRepresentation:MGSScriptRepresentationExecute];
    NSColor *parameterLabelColor = _parameterCountLabelColourDisabled;
    if (executableRepresentation) {
        parameterLabelColor =_parameterCountLabelColourEnabled;
    }
    [self setParameterCountLabelColour:parameterLabelColor];
    
	// if parameters exist then show connector
	[[self actionView] setHasConnector: parameterCount > 0 ? YES : NO];
}

/*
 
 action view
 
 */
- (MGSActionView *)actionView
{
	if ([[self view] isKindOfClass:[MGSActionView class]]) {
		return (MGSActionView *)[self view];
	} else {	
		return nil;
	}
}

/*
 
 set left banner template image as inverted
 
 */
- (void)setInvertedLeftBannerImage:(BOOL)value
{
	if ([[leftBannerImageView image] isTemplate]) {
		// invert the template image
		// see the 10.5 App Kit release notes for info on this
		NSBackgroundStyle style = value ? NSBackgroundStyleDark : NSBackgroundStyleLight;
		[[leftBannerImageView cell] setBackgroundStyle:style];
	}
}

/*
 
 footer view did resize
 
 resize the view accordingly.
 
 it would be better if the view registered for NSViewFrameDidChangeNotification
 amd resized itself accordingly
 
 note that this code is repeated in the parameterview controller class where it is called
 descriptionViewDidResize.
 
 should be moved into the superclas and called bottomViewDidResize
 
 */
- (void)footerViewDidResize:(MGSActionInputFooterViewController *)controller oldSize:(NSSize)oldSize
{

	
	NSRect bannerViewFrame = [self.bannerView frame];
	NSRect topViewFrame = [self.topView frame];
	NSRect middleViewFrame = [self.middleView frame];
	
	// calc change in view height
	NSRect viewFrame = [[controller view] frame];
	CGFloat deltaY = viewFrame.size.height - oldSize.height;
	
	// calc new origins for frames
	bannerViewFrame.origin.y += deltaY;
	topViewFrame.origin.y += deltaY;
	middleViewFrame.origin.y += deltaY;
	
	// resize our view
	//
	// turn off subview resizing while we do so
	BOOL autoresizesSubviews = [[self view] autoresizesSubviews];
	[[self view] setAutoresizesSubviews:NO];
	NSSize viewSize = [[self view] frame].size;
	viewSize.height += deltaY;
	[self setFrameSize:viewSize];
	[[self view] setAutoresizesSubviews:autoresizesSubviews];
	
	// restore view frames
	[self.bannerView setFrame:bannerViewFrame];
	
	[self.topView setFrame:topViewFrame];
	
	[self.middleView setFrame:middleViewFrame];
	
	[self updateFooterPosition];
	
	[[self view] setNeedsDisplay:YES];
	
}

/*
 
 set view frame size
 
 */
- (void)setFrameSize:(NSSize)size
{
	[[self view] setFrameSize:size];
	
	// note that I am fighting against the view system here.
	// it would have been much easier to use the notifications that
	// NSViews send out whenever its frame changes.
	//if (self.delegate && [self.delegate respondsToSelector:@selector(parameterViewDidResize:)]) {
	//	[self.delegate parameterViewDidResize:self];
	//}
}


#pragma mark MGSRoundedPanelView delegate methods
/*
 
 mouse down event
 
 */
- (void)mouseDown:(NSEvent *)theEvent
{
	[super mouseDown:theEvent];
	
	// inform delegate that view is now highlighted
	//if (self.delegate && [self.delegate respondsToSelector:@selector(actionViewHighlighted:)]) {
	//	[self.delegate actionViewHighlighted:self];
	//}
	
	// hit-test the description text
	//NSPoint mouseLoc = [[self view] convertPoint:[theEvent locationInWindow] fromView:nil];	// convert to view co-ordinates
	//if (NSMouseInRect(mouseLoc, [[_descriptionViewController view] frame], [[_descriptionViewController view] isFlipped])) {
	//	[_descriptionViewController toggleDescriptionDisclosure];
	//}
}
@end

@implementation MGSActionViewController (Private)

@end
