//
//  MGSResultWindowController.m
//  Mother
//
//  Created by Jonathan on 15/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSResultWindowController.h"
#import "MGSResultViewController.h"
#import "MGSResult.h"
#import "NSView_Mugginsoft.h"
#import "NSWindow_Mugginsoft.h"
#import "MGSTaskSpecifier.h"
#import "MGSNetClient.h"
#import "MGSToolbarController.h"
#import "MGSNotifications.h"
#import "MGSPopupButton.h"
#import "MGSResultToolViewController.h"

static int toolbarID = 0;

@interface MGSResultWindowController()
- (void)viewConfigChangeRequest:(NSNotification *)notification;
@end

@implementation MGSResultWindowController

/*
 
 init
 
 */
- (id)init
{
	[super initWithWindowNibName:@"ResultWindow"];
	return self;
}
/* 
 
 window did load
 
 */
- (void)windowDidLoad
{
	[[self window] setDelegate:self];
	
	
	// load the toolbar nib
	_toolbarController = [[MGSToolbarController alloc] init];
	_toolbarController.window = [self window];
	_toolbarController.style = MGSToolbarStyleResult;
	_toolbarController.identifier = [NSString stringWithFormat:@"result %i", toolbarID++];	// must be unique otherwise toolbars become synchronised!
	[_toolbarController loadNib];
	[_toolbarController setDelegate:self];
	
	// register notifications
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewConfigChangeRequest:) name:MGSNoteViewConfigChangeRequest object:[self window]];
	
	// note that when these were defined as objects within the nib
	// it caused horrible intermittent crashes.
	// so having a controller in a nib which loads its own nib seems
	// to be a recipe for disaster.
	// its hard to know when the data for this becomes available though.
	// so set a delegate and get- viewDidload when view loads.
	_resultViewController = [[MGSResultViewController alloc] initWithDelegate:self];

	// set the request view
	[[view superview] replaceSubview:view withViewFrameAsOld:[_resultViewController view]];
	view = [_resultViewController view];
}

/*

 result config change request
 
 */
- (void)viewConfigChangeRequest:(NSNotification *)notification
{ 
	// view config 
	NSNumber *number = [[notification userInfo] objectForKey:MGSNoteViewConfigKey];
	if (!number) return;
	eMGSMotherViewConfig viewConfig = [number integerValue];
	
	// get view state
	number = [[notification userInfo] objectForKey:MGSNoteViewStateKey];
	if (!number) return;
	eMGSViewState viewState = [number integerValue];
	
	if (viewState != kMGSViewStateShow) return;
	
	eMGSMotherResultView viewMode = kMGSMotherResultViewFirst;
	
	switch (viewConfig) {
		case kMGSMotherViewConfigDocument:
			viewMode = kMGSMotherResultViewDocument;
			break;
			
		case kMGSMotherViewConfigIcon:
			viewMode = kMGSMotherResultViewIcon;
			break;
			
		case kMGSMotherViewConfigList:
			viewMode = kMGSMotherResultViewList;
			break;

        case kMGSMotherViewConfigLog:
			viewMode = kMGSMotherResultViewLog;
			break;
            
		default:
			return;
	}
	
	[_resultViewController setViewMode:viewMode];
	
	// send view config did change notification
	NSNotification *noteDone = [NSNotification notificationWithName:MGSNoteViewConfigDidChange 
															 object:[self window]
														   userInfo:[notification userInfo]];
	[[NSNotificationCenter defaultCenter] postNotification:noteDone];
}


/*
 
 Set the result object to view
 
 */
- (void)setResult:(MGSResult *)aResult
{	
	_resultViewController.result = aResult;
	
	NSURL *url = [NSURL fileURLWithPath:@"anything"];
	[[self window] setRepresentedURL:url];
	
	MGSTaskSpecifier *action = aResult.action;
	NSImage *img = [[action netClient] hostIcon];
	[img setSize:NSMakeSize(16, 16)];  // scale your image if needed (and maybe should use userSpaceScaleFactor)
	[[[self window] standardWindowButton:NSWindowDocumentIconButton] setImage:img];
}

// NSWindowController will have registered us for this notification
- (void)windowWillClose:(NSNotification *)notification
{
	#pragma unused(notification)
	
	if (_delegate && [_delegate respondsToSelector:@selector(resultWindowWillClose:)]) {
		[_delegate resultWindowWillClose:self];
	}
	
	// it is advised not to unregister from notification centre in finalize method 
	// so implement a dispose to clean up notifications etc
	//[requestViewController dispose];
}

/*
 
 Delegate
 
 */
- (void)setDelegate:(id <MGSResultWindow>) object
{
	_delegate = object;
}
 
/*

window did resign key

*/
- (void)windowDidResignKey:(NSNotification *)notification
{
	#pragma unused(notification)
	
	[[self window] endEditing];
}


// commit pending edits in all views
- (BOOL)commitPendingEdits
{
	if (![_resultViewController commitEditing]) {
		return NO;
	}
	return YES;
}

#pragma mark View handling
/*
 
 active result view controller
 
 */
- (MGSResultViewController *)activeResultViewController
{
	return _resultViewController;
}
#pragma mark NSWindow delegate messages

/*
 
 window should close
 
 */
- (BOOL)windowShouldClose:(id)window
{

	#pragma unused(window)
	
	// commit any edits
	if (![self commitPendingEdits]) {
		return NO;
	}

	
	return YES;
}
@end
