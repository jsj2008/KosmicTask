//
//  MGSMinimalViewToolViewController.m
//  Mother
//
//  Created by Jonathan on 21/09/2009.
//  Copyright 2009 mugginsoft.com. All rights reserved.
//

#import "MGSMinimalViewToolViewController.h"
#import "MGSMotherModes.h"
#import "MGSNotifications.h"

#define SEG_MINIMAL 0

// class extension
@interface MGSMinimalViewToolViewController()
- (void)viewConfigDidChange:(NSNotification *)notification;
- (void)updateSegmentedControl;
@end

@implementation MGSMinimalViewToolViewController

/*
 
 awake from nib
 
 */
- (void)awakeFromNib
{	
}

/*
 
 initialise
 
 */
- (void)initialiseForWindow:(NSWindow *)window
{
	NSAssert(window, @"window is nil");
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewConfigDidChange:) name:MGSNoteViewConfigDidChange object:window];

	[self updateSegmentedControl];
}

/*
 
 - updateSegmentedControl
 
 */
- (void)updateSegmentedControl
{
	NSString *imageName = @"ToggleViewTemplateUp";
	if ([segmentedButtons isSelectedForSegment:SEG_MINIMAL]) {
		imageName = @"ToggleViewTemplate";
	} 
	NSImage *image = [NSImage imageNamed:imageName];
	[segmentedButtons setImage:image forSegment:SEG_MINIMAL];
}

/*
 
 segmented control click
 
 */
- (IBAction)segControlClicked:(id)sender
{
	[self segmentClick:[sender selectedSegment]];
}

/*
 
 segment click
 
 */
- (void)segmentClick:(NSInteger)selectedSegment
{
	eMGSMotherViewConfig viewConfig;
	eMGSViewState viewState = kMGSViewStateNormalSize;
	
	switch (selectedSegment) {
		case SEG_MINIMAL:
			viewConfig = kMGSMotherViewConfigMinimal;
			if ([segmentedButtons isSelectedForSegment:selectedSegment]) {
				viewState = kMGSViewStateMinimalSize;
			} else {
				viewState = kMGSViewStateNormalSize;
			}
			break;
						
		default:
			NSAssert(NO, @"bad segment");
			return;
			
	}
	
	// post view mode changed notification
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
						  [NSNumber numberWithInteger:viewConfig], MGSNoteViewConfigKey ,
						  [NSNumber numberWithInteger:viewState], MGSNoteViewStateKey ,
						  nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteViewConfigChangeRequest object:[[self view] window] userInfo:dict];
	
}

#pragma mark NSNotificationCenter callbacks

/*
 
 view config did change 
 
 */
- (void)viewConfigDidChange:(NSNotification *)notification
{
	
	NSNumber *number = [[notification userInfo] objectForKey:MGSNoteViewConfigKey];
	if (!number) return;
	int viewConfig = [number intValue];
	
	// sync GUI to view state
	switch (viewConfig) {
			
		case kMGSMotherViewConfigMinimal:;
			int idx = SEG_MINIMAL;
			number = [[notification userInfo] objectForKey:MGSNoteViewStateKey];
			if (!number) return;
			eMGSViewState viewState = [number integerValue];
			BOOL selected = YES;
			switch (viewState) {
				case kMGSViewStateNormalSize:
					selected = NO;
					break;
					
				case kMGSViewStateMinimalSize:
					selected = YES;
					break;
					
				default:
					return;
			}
			[segmentedButtons setSelected:selected forSegment:idx];

			break;
			
		default:
			break;
			
	}
	
	[self updateSegmentedControl];
}

@end
