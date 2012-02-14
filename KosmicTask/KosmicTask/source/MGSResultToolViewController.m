//
//  MGSResultToolViewController.m
//  Mother
//
//  Created by Jonathan on 27/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSResultToolViewController.h"
#import "MGSMotherModes.h"
#import "MGSNotifications.h"

#define SEG_DOCUMENT 0
#define SEG_ICON 1
#define SEG_LIST 2
#define SEG_LOG 3
#define SEG_SCRIPT 4


// class extension
@interface MGSResultToolViewController()
- (void)viewConfigDidChange:(NSNotification *)notification;
@end

@implementation MGSResultToolViewController

@synthesize actionPopupButton;

/*
 
 initialise
 
 */
- (void)initialiseForWindow:(NSWindow *)window
{
	NSAssert(window, @"window is nil");
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewConfigDidChange:) name:MGSNoteViewConfigDidChange object:window];
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
- (void)segmentClick:(int)selectedSegment
{
	eMGSMotherViewConfig viewConfig = kMGSMotherViewConfigDocument;
	eMGSViewState viewState = kMGSViewStateShow;
	
	switch (selectedSegment) {
		case SEG_LIST:
			viewConfig = kMGSMotherViewConfigList;
			break;

		case SEG_ICON:
			viewConfig = kMGSMotherViewConfigIcon;
			break;		
			
		case SEG_DOCUMENT:
			viewConfig = kMGSMotherViewConfigDocument;
			break;
			
		case SEG_SCRIPT:
			viewConfig = kMGSMotherViewConfigScript;
			break;		

        case SEG_LOG:
			viewConfig = kMGSMotherViewConfigLog;
			break;
            
		default:
			NSAssert(NO, @"bad segment");
			return;
			
	}
	
	// post view mode change request notification
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
						  [NSNumber numberWithInteger:viewConfig], MGSNoteViewConfigKey,
						  [NSNumber numberWithInteger:viewState], MGSNoteViewStateKey,
						  nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteViewConfigChangeRequest object:[[self view] window] userInfo:dict];
	
}

/*
 
 view config did change 
 
 */
- (void)viewConfigDidChange:(NSNotification *)notification
{
	// view config
	NSNumber *number = [[notification userInfo] objectForKey:MGSNoteViewConfigKey];
	if (!number) return;
	eMGSMotherViewConfig viewConfig = [number integerValue];
	
	// view state
	number = [[notification userInfo] objectForKey:MGSNoteViewStateKey];
	if (!number) return;
	eMGSViewState viewState = [number integerValue];
	
	if (viewState != kMGSViewStateShow) return;
	
	int segment = SEG_DOCUMENT;
	
	// ensure correct segment is selected
	switch (viewConfig) {
		case kMGSMotherViewConfigList:
			segment = SEG_LIST;
			break;
			
		case kMGSMotherViewConfigIcon:
			segment = SEG_ICON;
			break;		
			
		case kMGSMotherViewConfigDocument:
			segment = SEG_DOCUMENT;
			break;
			
		case kMGSMotherViewConfigScript:
			segment = SEG_SCRIPT;
			break;		

        case kMGSMotherViewConfigLog:
			segment = SEG_LOG;
			break;
            
		default:
			NSAssert(NO, @"bad view mode");
			return;
			
	}
	
	if ([segmentedButtons selectedSegment] != segment) {
		[segmentedButtons setSelectedSegment:segment]; 
	}
}

@end
