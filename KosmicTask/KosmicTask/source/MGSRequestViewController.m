//
//  MGSRequestViewController.m
//  Mother
//
//  Created by Jonathan on 01/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSRequestViewController.h"
#import "MGSRequestTabViewController.h"
#import "MGSNetClient.h"
#import "MGSNetMessage.h"
#import "MGSClientScriptManager.h"
#import "MGSScriptPlist.h"
#import "MGSInputRequestViewController.h"
#import "MGSOutputRequestViewController.h"
#import "MGSRequestTabViewController.h"
#import "MGSWaitViewController.h"
#import "MGSScript.h"
#import "NSView_Mugginsoft.h"
#import "NSViewController_Mugginsoft.h"
#import "NSSplitView_Mugginsoft.h"
#import "MGSTaskSpecifier.h"
#import "MGSTaskSpecifierManager.h"
#import "MGSRequestProgress.h"
#import "MGSClientRequestManager.h"
#import "MGSNetRequestPayload.h"
#import "MGSResultViewHandler.h"
#import "MGSResultController.h"
#import "MGSResult.h"
#import "MGSNotifications.h"
#import "MGSActionActivityView.h"
#import "MGSCapsuleTextCell.h"
#import "MGSResultFormat.h"
#import "MGSPreferences.h"

#define MIN_LEFT_SPLITVIEW_WIDTH 320
#define MIN_RIGHT_SPLITVIEW_WIDTH 440


NSString *MGSInputViewActionContext = @"MGSInputViewActionContext";
NSString *MGSOutputViewTaskResultDisplayLockedContext = @"MGSOutputViewTaskResultDisplayLockedContext";
NSString *MGSInputActionSelectionIndexContext = @"MGSInputActionSelectionIndexContext";
NSString *MGSOutputResultSelectionIndexContext = @"MGSOutputResultSelectionIndexContext";

// class extension
@interface MGSRequestViewController()
- (void)actionInputModified:(NSNotification *)notification;
- (void)actionSaved:(NSNotification *)note;
-(void)executeResponse:(MGSNetRequest *)netRequest payload:(MGSNetRequestPayload *)payload;
-(void)getScriptResponse:(MGSNetRequest *)netRequest payload:(MGSNetRequestPayload *)payload;
@end

@implementation MGSRequestViewController

//@synthesize view;

@synthesize delegate = _delegate;
@synthesize viewEffect = _viewEffect;
@synthesize inputViewController = _inputViewController;
@synthesize outputViewController = _outputViewController;
@synthesize observesInputModifications = _observesInputModifications;
@synthesize emptyRequestView = _emptyRequestView;
@synthesize sendCompletedActionSpecifierToHistory = _sendCompletedActionSpecifierToHistory;

#pragma mark Instance
/*
 
 init
 
 */
- (id)init
{
	return [super initWithNibName:@"RequestView" bundle:nil];
}


/* 
 
 awake from nib
 
 */
- (void) awakeFromNib 
{
	if (_nibLoaded) {
		return;
	}
	
	self.observesInputModifications = YES;
	_nibLoaded = YES;
	_requestView = [self view];
	_viewEffect = NSView_animateEffectNone;	// don't fade in the initial view
	_sendCompletedActionSpecifierToHistory = YES;
	
	_icon = nil;
	_iconName = nil;
	_objectCount = 0;
	controller = [[NSObjectController alloc] initWithContent:self];
	
	// be careful trying to load another nib in awakeFromNib
	// as an infinite loop will occur as awakeFromNib is also
	// sent to file's owner!
	// hence nib load flag
	_inputViewController = [[MGSInputRequestViewController alloc] initWithNibName:@"InputRequestView" bundle:nil];
	_outputViewController = [[MGSOutputRequestViewController alloc] initWithNibName:@"OutputRequestView" bundle:nil];
	
	_inputViewController.delegate = self;
	_outputViewController.delegate = self;
	haveAutomatedKeepActionDisplayed = NO;
	
	// load the views
	[_inputViewController view];
	[_outputViewController view];
	
	[splitView replaceSubview:leftView withViewSizedAsOld:[_inputViewController view]];
	leftView = [_inputViewController view];
	
	[splitView replaceSubview:rightView withViewSizedAsOld:[_outputViewController view]];
	rightView = [_outputViewController view];

	// show the wait view until client data is obtained
	//_waitViewController = [[MGSWaitViewController alloc] initWithNibName:@"WaitView" bundle:nil];
	//[self setView:[_waitViewController view]];
	
	// observe the input view action.
	// this may be modified by passing an action into the controller or by the controller
	// internally selecting and exiting completed action
	[_inputViewController addObserver:self forKeyPath:@"action" 
							  options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionPrior) context:MGSInputViewActionContext];
	[_inputViewController addObserver:self forKeyPath:@"selectedIndex" options:0 context:MGSInputActionSelectionIndexContext];
	
	// observe task result locking in output view
	[_outputViewController addObserver:self forKeyPath:@"taskResultDisplayLocked" options:0 context:MGSOutputViewTaskResultDisplayLockedContext];
	[_outputViewController addObserver:self forKeyPath:@"selectedIndex" options:0 context:MGSOutputResultSelectionIndexContext];
	
	// notifications
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(actionSaved:) name:MGSNoteActionSaved object:nil];

	// input view task result display locking follows output
	_inputViewController.taskResultDisplayLocked = _outputViewController.taskResultDisplayLocked;
	
	// show empty request view
	[self.emptyRequestView setFrame:[[self view] frame]];
	[[self view] addSubview:self.emptyRequestView];
	
	// initialise the empty request view properties
	// - could make a separate controller
	_actionActivityView.activity = MGSTerminatedTaskActivity;
	NSCell *cell = [_emptyRequestViewTextField cell];
	if ([cell isKindOfClass:[MGSCapsuleTextCell class]]) {
		[(MGSCapsuleTextCell *)cell setCapsuleHasShadow:YES];
	}
}

/*
 
 finalize
 
 */
- (void)finalize
{
#ifdef MGS_LOG_FINALIZE
	MLog(DEBUGLOG, @"finalized");
#endif
    
	[super finalize];
}

/*
 
 set the delegate
 
 */
- (void)setDelegate:(id)aDelegate
{
	_delegate = aDelegate; 
}


/*
 
 - dispose
 
 */
- (void)dispose
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [_inputViewController dispose];
    [_outputViewController dispose];
}
#pragma mark KVO
/*
 
 observe value for key path
 
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	#pragma unused(keyPath)
	#pragma unused(object)
	
	// input action has changed
	if (context == MGSInputViewActionContext) {
		
		// action about to change
		if ([change objectForKey:NSKeyValueChangeNotificationIsPriorKey]) {
			if ([[self delegate] respondsToSelector:@selector(requestViewActionWillChange:)]) {
				[[self delegate] requestViewActionWillChange:self];
			}
				
		} else {
			
			if ([[self delegate] respondsToSelector:@selector(requestViewActionDidChange:)]) {
				[[self delegate] requestViewActionDidChange:self];
			}
		}
	}
	
	// input task result display locking follows output
	else if (context == MGSOutputViewTaskResultDisplayLockedContext) {
		_inputViewController.taskResultDisplayLocked = _outputViewController.taskResultDisplayLocked;
	}
	
	// input action selection index context
	else if (context == MGSInputActionSelectionIndexContext) {
		_outputViewController.selectedPartnerIndex = _inputViewController.selectedIndex;
	}
	
	// output result selection index context
	else if (context == MGSOutputResultSelectionIndexContext) {
		_inputViewController.selectedPartnerIndex = _outputViewController.selectedIndex;
	}
	
	// input view controller is processing
	else if (context == MGSIsProcessingContext) {
		[self willChangeValueForKey:@"isProcessing"];
		[self didChangeValueForKey:@"isProcessing"];
	}
	
	
}
/*
 
 set observes input modifications
 
 the controller may not be required to observe changes for a given window
 if there is one than one intstance of the view within the window
 
 */
- (void)setObservesInputModifications:(BOOL)value
{
	
	if (value == _observesInputModifications) {
		return;
	}

	_observesInputModifications = value;
	
	if (_observesInputModifications) {
		
		// register to receive action input change notification
		// note that we cannot set object to [[self view] window] as view may not yet have been added to a windows view hierarchy
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(actionInputModified:) name:MGSNoteActionInputModified object:nil];
	} else {
		
		// remove observer
		[[NSNotificationCenter defaultCenter] removeObserver:self name:MGSNoteActionInputModified object:nil];
	}

}
#pragma mark Task handling
//===================================================
//
// current action input modified
//
//===================================================
- (void)actionInputModified:(NSNotification *)notification
{
	if (![self notificationObjectIsWindow:notification]) return;
	
	[self actionInputModified];
}

/*
 
 action specifier
 
 */
- (MGSTaskSpecifier *)actionSpecifier
{
	// the input view controller caches completed actions
	// so only it knows the current action
	return [_inputViewController action];
}

//===============================================================
//
// set action to be performed
//
//
//===============================================================
- (void)setActionSpecifier:(MGSTaskSpecifier *)actionSpec
{
	
	// determine if content view needs replaced
	NSView *newView = nil;
	NSView *contentView = [[[self view] subviews] objectAtIndex:0];
	if (!actionSpec || !actionSpec.script) {
		if (contentView != self.emptyRequestView) {
			newView =  self.emptyRequestView;
		}
	} else {
		if (contentView != splitView) {
			newView =  splitView;
		}
	}
	
	// set to nil when action is changing or tab is closing.
	// required when the client for the last tab
	// becomes unavailable.
	// in this case the tab cannot be closed.
	// the nil value tells the controller
	// not to try and remove the action observer again ->exception.
	if (!actionSpec) {
		if (newView) {
			[[self view] replaceSubview:contentView withViewFrameAsOld:newView];
		}
		goto commonExit;
	}
	
	// we need at a least a display representation of our script.
	// normally we will encounter a minimal preview representation which cannot be executed
	// or fully displayed
	if (![[actionSpec script] canConformToRepresentation:MGSScriptRepresentationDisplay]) {
		
		// option defines representation type
		NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
								[NSNumber numberWithInteger:MGSScriptRepresentationDisplay], MGSScriptKeyRepresentation,
								 nil];
		
		// request a display representation
		displayNetRequest = [[MGSClientRequestManager sharedController] 
									 requestScriptWithUUID:[[actionSpec script] UUID] 
										netClient:[actionSpec netClient] 
									 withOwner:self
									 options:options];
		displayNetRequest.ownerObject = actionSpec;
		
		// we use the current representation until the requested representation is received
	}
	
	// remove previous observers
	if ([_inputViewController action]) {
		@try {
			[_inputViewController removeObserver:self forKeyPath:@"isProcessing"];
		} 
		@catch (NSException *e) {
			MLog(RELEASELOG, @"%@", [e reason]);
		}
	}
	
	// if the action script is nil then no valid action is available.
	[_inputViewController setAction:actionSpec];
	[_outputViewController setAction:actionSpec];
	[_inputViewController addObserver:self forKeyPath:@"isProcessing" options:NSKeyValueObservingOptionInitial context:MGSIsProcessingContext];
	
	// show new view if reqd
	if (newView) {
		[[self view] replaceSubview:contentView withViewFrameAsOld:newView];
	}

commonExit:
	
	return;
}

/*
 
 determine if action specifier can be set for this view
 
 */
- (BOOL)permitSetActionSpecifier
{
	if (NO == [self isProcessing] && NO == [self keepActionDisplayed]) {
		return YES;
	}
	
	return NO;
}

/*
 
 keep the request action displayed
 
 */
- (BOOL)keepActionDisplayed
{
	return [_inputViewController keepActionDisplayed];
}

#pragma mark NSNotificationCenter callbacks
/*
 
 action input modified
 
 */
- (void)actionInputModified
{
	[_inputViewController actionInputModified];
	
	//resetting action resets progress etc
	[_outputViewController setAction:[_inputViewController action]];
	
	[_outputViewController actionInputModified];
}

/*
 
 action saved notification
 
 send whenever an action is saved
 
 */
- (void)actionSaved:(NSNotification *)note
{
	// get the action being saved
	MGSTaskSpecifier *savedAction = [note object];
	if (![savedAction isKindOfClass:[MGSTaskSpecifier class]]) return;
	
	// is this an instance of our current action?
	if (![savedAction isEqualUUID:[self actionSpecifier]]) {
		return;
	}
	
	// our represented action has been saved so request an update
	[[NSNotificationCenter defaultCenter] 
			postNotificationName:MGSNoteRefreshAction 
			object:self 
			userInfo:nil];
}


#pragma mark Properties
//
// these values are observed by the PSMTabBarControl
//

/*
 
 action is processing 
 
 */
- (BOOL)isProcessing
{
	return [[self actionSpecifier] isProcessing];
}
/*
- (void)setIsProcessing:(BOOL)value
{
	[_actionSpecifier setIsProcessing:value];
}
*/
/*
 
 icon
 
 */
- (NSImage *)icon
{
    return _icon;
}

/*
 
 set icon
 
 */
- (void)setIcon:(NSImage *)icon
{
    [icon retain];
    [_icon release];
    _icon = icon;
}

/* 
 
 icon name
 
 */
- (NSString *)iconName
{
    return _iconName;
}


/* 
 
 set icon name
 
 */
- (void)setIconName:(NSString *)iconName
{
    [iconName retain];
    [_iconName release];
    _iconName = iconName;
}


/* 
 
 object count
 
 */
- (int)objectCount
{
    return _objectCount;
}


/*
 
 set object controller
 
 */
- (void)setObjectCount:(int)value
{
    _objectCount = value;
}

/*
 
 controller
 
 */
- (NSObjectController *)controller
{
    return controller;
}

#pragma mark Task execution

/*
 
 execute the current script with current parameters
 
 */
- (IBAction)executeScript:(id)sender
{
	#pragma unused(sender)
	
	NSAssert([self actionSpecifier], @"action specifier is nil");
	
	// reset action prior to execution.
	// this resets progress etc.
	// can be improved upon
	[_outputViewController setAction:[_inputViewController action]];

	if ([_inputViewController canExecute]) {
		
		// do want to automatically keep executed actions displayed
		BOOL keepExecutedActionsDisplayed = [[NSUserDefaults standardUserDefaults] boolForKey:MGSKeepExecutedTasksDisplayed];
		
		if (!haveAutomatedKeepActionDisplayed && keepExecutedActionsDisplayed) {
			_inputViewController.keepActionDisplayed = YES;
			haveAutomatedKeepActionDisplayed = YES;
		}

		
		[[self actionSpecifier] execute:self];
	}
}

/*
 
 terminate the current script 
 
 */
- (IBAction)terminateScript:(id)sender
{
	#pragma unused(sender)
	
	NSAssert([self actionSpecifier], @"action specifier is nil");
	[[self actionSpecifier] terminate:nil];
}

/*
 
 suspend the current script 
 
 */
- (IBAction)suspendScript:(id)sender
{
	#pragma unused(sender)
	
	NSAssert([self actionSpecifier], @"action specifier is nil");
	[[self actionSpecifier] suspend:nil];
}

/*
 
 resume the current script 
 
 */
- (IBAction)resumeScript:(id)sender
{
	#pragma unused(sender)
	
	NSAssert([self actionSpecifier], @"action specifier is nil");
	[[self actionSpecifier] resume:nil];
}


#pragma mark Tabs

/*
 
 close the tab for this request
 
 */
-(void)closeRequestTab
{
	if (_delegate && [_delegate respondsToSelector:@selector(closeTabForRequestView:)]) {
		[_delegate closeTabForRequestView:self];
	}
}

#pragma mark View mode

/*
 
 toggle view mode
 
 
 */
- (void)toggleViewMode:(eMGSMotherViewConfig)mode
{
	NSAssert (mode == kMGSMotherViewConfigMinimal, @"invalid view mode");
	
}

#pragma mark - MGSInputRequestViewController and MGSOutputRequestViewController delegate methods
/*
 
 sync partner selected index
 
 */
- (void)syncPartnerSelectedIndex:(id)sender
{
	if (sender == _inputViewController) {
		[_outputViewController syncToPartnerSelectedIndex];
	} else {
		[_inputViewController syncToPartnerSelectedIndex];
	}
}

/*
 
 should resize by size delta
 
 */
- (BOOL)shouldResizeWithSizeDelta:(NSSize)sizeDelta
{
	NSSize size = [[self view] frame].size;
	
	// if right view >= min size then resizing should proceed
	if (size.width + sizeDelta.width >= self.minViewWidth) {
		//MLog(DEBUGLOG, @"shouldResizeWithSizeDelta: YES");
		return YES;
	} else {
		//MLog(DEBUGLOG, @"shouldResizeWithSizeDelta: NO");
		return NO;
	}
	
}

/*
 
 min view width
 
 */
- (CGFloat)minViewWidth
{
	return MIN_RIGHT_SPLITVIEW_WIDTH + MIN_LEFT_SPLITVIEW_WIDTH + [splitView dividerThickness];
}

#pragma mark - NSSplitView delegate methods

//
// size splitview subviews as required
//
- (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize: (NSSize)oldSize
{	
	//MLog(DEBUGLOG, @"splitView:resizeSubviewsWithOldSize:");
	MGSSplitviewBehaviour behaviour;
	
	NSSize size = [sender frame].size;
	CGFloat delta = oldSize.width - size.width;
	CGFloat rightViewWidth = size.width + delta - [leftView frame].size.width - [splitView dividerThickness];
	
	NSArray *minWidthArray = [NSArray arrayWithObjects:[NSNumber numberWithDouble:MIN_LEFT_SPLITVIEW_WIDTH], [NSNumber numberWithDouble:MIN_RIGHT_SPLITVIEW_WIDTH], nil];
	
	// if right view >= min size then resizing right view
	if (rightViewWidth >= MIN_RIGHT_SPLITVIEW_WIDTH) {
		behaviour = MGSSplitviewBehaviourOf2ViewsFirstFixed;
	} else {
		// resize left view
		behaviour = MGSSplitviewBehaviourOf2ViewsSecondFixed;
	}
		 
	// see the NSSplitView_Mugginsoft category
	[sender resizeSubviewsWithOldSize:oldSize withBehaviour:behaviour minSizes:minWidthArray];
}

/*
 
 splitview constrain split position
 
 note that - (CGFloat)splitView:(NSSplitView *)sender constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)offset
 would be more efficient
 
 */
- (CGFloat)splitView:(NSSplitView *)sender constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)offset
{
	#pragma unused(offset)
	
	// min left view width
	if (proposedPosition < MIN_LEFT_SPLITVIEW_WIDTH) {
		proposedPosition = MIN_LEFT_SPLITVIEW_WIDTH;
	} else {
	
		// min right view width
		CGFloat width = [sender frame].size.width;
		if (width - proposedPosition - [splitView dividerThickness] < MIN_RIGHT_SPLITVIEW_WIDTH) {
			proposedPosition = width - [splitView dividerThickness] - MIN_RIGHT_SPLITVIEW_WIDTH;
		}
	}
	
	return proposedPosition;
}

/*
 
 get additional rect to be used to drag splitview
 
 */
- (NSRect)splitView:(NSSplitView *)aSplitView additionalEffectiveRectOfDividerAtIndex:(NSInteger)dividerIndex
{	
	#pragma unused(aSplitView)
	#pragma unused(dividerIndex)
	
	// rect must be in splitview co-ords
	NSRect rect = [_inputViewController splitViewRect];
	
	// this is required but view flipping must be occurring which pushes the view to the bottom.
	// due to view geometry the original rect is good enough
	//NSRect viewRect = [aSplitView convertRect:rect fromView:[_inputViewController view]];
	
	return rect;
}

#pragma mark - MGSNetRequest owner methods

/*
 
 net request will send
 
 */
-(NSDictionary *)netRequestWillSend:(MGSNetRequest *)netRequest
{
	#pragma unused(netRequest)
	
	// return a configuration dictionary
	MGSScript *script = [[self actionSpecifier] script];
	
	double timeout = [script timeout];
	return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:timeout], @"ReadTimeout", [NSNumber numberWithDouble:timeout], @"WriteTimeout", nil];
}

/*
 
 net request update 
 
 sent when the request moves between states ie:
 
 ready
 sending
 executing
 receiving
 
 */
-(void)netRequestUpdate:(MGSNetRequest *)netRequest
{		
	MGSRequestProgress *actionRequestProgress = [self actionSpecifier].requestProgress;
	eMGSRequestProgress prevProgressValue = actionRequestProgress.value;
	
	// update progress from status.
	// note that some status changes do not produce a progress change.
	[actionRequestProgress setValueFromStatus:netRequest.status];
	
	// if the progress has changed then output
	if (actionRequestProgress.value != prevProgressValue) {
		[_outputViewController setRequestProgress:actionRequestProgress.value];
	}
	
	// use the net request to update the current progress object
	[netRequest updateProgress:[_outputViewController progress]];
	
	[self actionSpecifier].requestProgress.overviewString = [_outputViewController progress].overviewString;
}

/*
 
 - netRequestChunkReceived:
 
 */
-(void)netRequestChunkReceived:(MGSNetRequest *)netRequest
{
    if (netRequest.requestType == kMGSRequestTypeLogging) {
        
        // iterate over the available chunks
        for (NSString *chunk in netRequest.chunksReceived) {
            [_outputViewController addLogString:chunk];
        }
    }
}
/*
 
 - netRequestResponse:payload:
 
 */
-(void)netRequestResponse:(MGSNetRequest *)netRequest payload:(MGSNetRequestPayload *)payload
{
	MGSNetClient *netClient = netRequest.netClient;
	NSAssert([[self actionSpecifier] netClient] == netClient, @"net client does not match action specifier");

	// if action was terminated by user then ignore response
	if ([self actionSpecifier].runStatus == MGSTaskRunStatusTerminatedByUser) {
		return;
	}
		
	NSString *requestCommand = netRequest.kosmicTaskCommand;
	if ([requestCommand caseInsensitiveCompare:MGSScriptCommandExecuteScript] == NSOrderedSame) {
		
		[self executeResponse:netRequest payload:payload];
		
	} else if ([requestCommand caseInsensitiveCompare:MGSScriptCommandGetScriptUUID] == NSOrderedSame) {
		
		[self getScriptResponse:netRequest payload:payload];
		
	} else {
		[MGSError clientCode:MGSErrorCodeInvalidCommandReply reason:requestCommand];
	}
	
	
}

/*
 
 - executeResponse:payload:
 
 */
-(void)executeResponse:(MGSNetRequest *)netRequest payload:(MGSNetRequestPayload *)payload
{
	// display the progress table now rather than waiting for the runloop.
	// this gives better progress feedback.
	[_outputViewController progressDisplay];
		
	// parse request errors
	if (netRequest.error) {
		switch (netRequest.error.code) {
				
				// a read timout will occur if a reply from the action is not received with the read timeout period.
				// this implies that the action is still running on the server.
				// if the action is flagged as still processing then send a terminate request.
			case MGSErrorCodeSocketReadTimeoutError:
				// terminate the action
#pragma mark warning this is poor design. the server should be timing out the action, not the client.
				if ([[self actionSpecifier] isProcessing]) {
					[[self actionSpecifier] terminate:nil];
				}
				break;
				
			case  MGSErrorCodeAuthenticationFailure:
				// fall thru
			default:
				[[self actionSpecifier] taskDidCompleteWithError:netRequest.error];
				break;
				
		}
	} else {
		[[self actionSpecifier] taskDidComplete];
	}
	
	// assume success until proven otherwise
	eMGSRequestProgress progress = MGSRequestProgressCompleteWithNoErrors;
	id progressObject = nil;
	id resultObject = nil;
	NSAttributedString *resultScriptString = nil;
	
	
	// check for request errors
	if (netRequest.error) {
		progress = MGSRequestProgressCompleteWithErrors;
		progressObject = netRequest.error;
		resultObject = progressObject;
	}
	
	// process the payload
	else if ([payload dictionary]) {
		
		// look for result dict
		NSDictionary *resultDict = [[payload dictionary] objectForKey:MGSScriptKeyResult];
		resultObject = [resultDict objectForKey:MGSScriptKeyResultObject];
		
		NSData *SourceRTFData =[resultDict objectForKey:MGSScriptKeySourceRTFData];
		resultScriptString = [[NSAttributedString alloc] initWithRTF:SourceRTFData documentAttributes:nil];
	} 
	
	// get std error.
	// shell error/logging sent via stderr
    //
    // logging should now be sent via a separate request in which
    // case it will not appear in the result dict. if it does however
    // we want to direct it to the logging view of the output request.
    //
	NSString *stdErrString = [[payload dictionary] objectForKey:MGSScriptKeyStdError];
	if (stdErrString) {
        
        // add log string to output view
        [_outputViewController addLogString:stdErrString];
        
        /*
		stdErrString = [NSString stringWithFormat:@"\n\nSTDERR output:\n\n%@", stdErrString];
		
		NSString *errorKey = [[MGSResultFormat errorKeys] objectAtIndex:0];
		NSDictionary *stdErrorDict = [NSDictionary dictionaryWithObjectsAndKeys:stdErrString, errorKey, nil];
		
		// retain the resultObject if it exists
		if (resultObject) {
			resultObject = [NSArray arrayWithObjects:resultObject, stdErrorDict, nil];
		} else {
			resultObject = stdErrorDict;
		}*/
	}
	
	// supply default result object if none defined
	if (!resultObject) {
		resultObject = [MGSResultViewHandler defaultResultObject];
	}
	
	// update the action progress.
	// thus essential marks the request as complete.
	[self actionSpecifier].requestProgress.value = progress;
	
	// create our result
	MGSResult *result = [[MGSResult alloc] init];
	result.object = resultObject;
	result.attachments = netRequest.responseMessage.attachments;
	result.resultScriptString = resultScriptString;	
    NSString *logString = [_outputViewController logString];
    if (logString){
        result.resultLogString = [[NSAttributedString alloc] initWithString:logString attributes:nil];
    }
	
    // add result string to progress
	[self actionSpecifier].requestProgress.resultString = [result shortResultString];
	
	//
	// add a copy of the completed action to the input view controller.
	// remember that [self actionSpecifier] resolves to [_inputViewController action].
	// the following line copies a copy of the action into the inputview.
	// hence [self actionSpecifier] returns a different instance after this call.
	//
	[[_inputViewController actionController] addCompletedActionCopy:[self actionSpecifier] withResult:result];
	
	// send action result to output view controller
	[_outputViewController addResult:result];
	
	// save successful actions to the history
	if (payload && !payload.requestError && self.sendCompletedActionSpecifierToHistory) {
		MGSTaskSpecifierManager *actionHistory = [[MGSTaskSpecifierManager sharedController] history];
		NSAssert(actionHistory, @"action history is nil");
		
		// preserve a copy of the action in the history
		[actionHistory insertObject:[[self actionSpecifier] historyCopy] atArrangedObjectIndex:0];
	} 
}	

/*
 
 - getScriptResponse:payload:
 
 */
-(void)getScriptResponse:(MGSNetRequest *)netRequest payload:(MGSNetRequestPayload *)payload
{
	// is the response for the current task.
	// if not, discard it.
	if (netRequest.ownerObject != [self actionSpecifier]) {
		return;
	}
	
	// get script from request dict
	NSMutableDictionary *scriptDict =[[payload dictionary] objectForKey:MGSScriptKeyScript];
	
	// if script dict is available
	if (scriptDict) {
		
		// get script
		MGSScript *script = [[MGSScript alloc] init];
		[script setDict:scriptDict];

		// copy the task spec and set the script
		MGSTaskSpecifier *taskSpec = [self.actionSpecifier mutableDeepCopyAsNewInstance];
		[taskSpec setScript:script];
		
		// update the action specifier
		self.actionSpecifier = taskSpec;
	}
}

@end


// messages received by this object as the owner of a request
@implementation MGSRequestViewController (MGSClientRequestManagerOwner)


@end
