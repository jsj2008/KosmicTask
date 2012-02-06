//
//  MGSOutputRequestViewController.m
//  Mother
//
//  Created by Jonathan on 05/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSPreferences.h"
#import "MGSOutputRequestViewController.h"
#import "MGSRequestViewController.h"
#import "NSSplitView_Mugginsoft.h"
#import "MGSResultViewHandler.h"
#import "MGSTimeIntervalTransformer.h"
#import "MGSResultController.h"
#import "MGSResultViewController.h"
#import "NSView_mugginsoft.h"
#import "MGSNotifications.h"
#import "MGSResult.h"
#import "MGSImageManager.h"
#import "MGSMotherModes.h"
#import "MGSActionActivityViewController.h"
#import "MGSTaskSpecifier.h"
#import "MGSNetRequest.h"
#import "MGSNetMessage.h"
#import "MGSGradientView.h"
#import "MGSNetClient.h"
#import "MGSNetClientContext.h"
#import "MGSApplicationMenu.h"
#import "MGSOutputRequestView.h"

#define SEG_DOCUMENT 0
#define SEG_ICON 1
#define SEG_LIST 2
#define SEG_SCRIPT 3

NSString *MGSRunStatusContext = @"MGSRunStatusContext";
static NSString *MGSActionProgressContext = @"MGSActionProgressContext";
static NSString *MGSProgressDurationContext = @"MGSProgressDurationContext";
static NSString *MGSResultSelectionIndexContext = @"MGSResultSelectionIndexContext";
static NSString *MGSViewModeContext = @"MGSViewModeContext";

@interface MGSOutputRequestViewController(Private)
- (void)addProgress:(MGSRequestProgress *)progress;
- (NSTimeInterval)progressDuration;
- (void)updateActivity;
- (NSInteger)selectedResultIndex;
- (void)setSelectedResultIndex:(NSInteger)index;
- (void)updateIndexMatchesPartnerIndex;
- (NSInteger)segmentIndexForViewMode:(eMGSMotherResultView)viewMode;
- (void)selectViewSegment:(NSInteger)index;
- (void)reset;
- (void)resetRequestProgress;
@end

@implementation MGSOutputRequestViewController

@synthesize delegate = _delegate;
@synthesize action = _action;
@synthesize showPrevResultEnabled = _showPrevResultEnabled;
@synthesize showNextResultEnabled = _showNextResultEnabled;
@synthesize resultPositionString = _resultPositionString;
@synthesize resultsAvailableForAction = _resultsAvailableForAction;
@synthesize progressArray = _progressArray;
@synthesize taskResultDisplayLocked = _taskResultDisplayLocked;
@synthesize indexMatchesPartnerIndex = _indexMatchesPartnerIndex;
@synthesize selectedPartnerIndex = _selectedPartnerIndex;
@synthesize selectedIndex = _selectedIndex;
@synthesize resultViewController = _resultViewController;

#pragma mark -
#pragma mark Instance control
/*
 
 awake from nib
 
 */
- (void)awakeFromNib
{
	_selectedPartnerIndex = NSNotFound;
	_selectedIndex = NSNotFound;
	
	[(MGSOutputRequestView *)[self view] setDelegate:self];
	
	// progress array controller
	_progressArrayController = [[NSArrayController alloc] init];
	[_progressArrayController setObjectClass:[MGSRequestProgress class]];	// add this class
	[_progressArrayController setAvoidsEmptySelection:NO];
	[_progressArrayController setSelectsInsertedObjects:NO];
	
	// result controller
	_resultController = [[MGSResultController alloc] init];
	
	// result view controller
	_resultViewController = [[MGSResultViewController alloc] init];
	[_resultViewController view];	// load it
	[_resultViewController setDelegate:self];
	[_resultViewController setViewModeImage:[viewModeSegmentedControl imageForSegment:[viewModeSegmentedControl selectedSegment]]];
	
	// action activity view controller
	_actionActivityViewController = [[MGSActionActivityViewController alloc] init];
	[_actionActivityViewController view]; // load it
	
	self.resultsAvailableForAction = NO;
	 
	// add default progress item
	[self resetRequestProgress];

	// do not keep last item selected
	[_progressTable setAllowsEmptySelection:YES];
	
	[[_resultActionPopup cell] setUsesItemFromMenu: YES];
    //[_resultActionPopup setShowsMenuWhenIconClicked: YES];
	
	_showNextResultEnabled = NO;
	_showPrevResultEnabled = NO;
	_resultPositionString = @"";
	
	// bind table columns to controller
	
	// object itself bound to image and text cell

	NSDictionary *defaultBindingOptions = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], NSCreatesSortDescriptorBindingOption, nil];
	NSMutableDictionary *bindingOptions = [NSMutableDictionary dictionaryWithDictionary:defaultBindingOptions];
	id column = [_progressTable tableColumnWithIdentifier:@"output"];
	[column bind:NSValueBinding toObject:_progressArrayController withKeyPath:@"arrangedObjects" options:bindingOptions];
	
	// time transformer.
	// could have used a subclassed formatter
	// see http://playosx.svn.sourceforge.net/viewvc/playosx/trunk/Formatters/
	MGSTimeIntervalTransformer *intervalTransformer = [[MGSTimeIntervalTransformer alloc] init];
	//_progressTimeResolution = MGSTime10msec;
	_progressTimeResolution = MGSTimeSecond;
	intervalTransformer.resolution = _progressTimeResolution;
	intervalTransformer.style = MGSTimeStyleTextual;
	intervalTransformer.returnAttributedString = NO;
	
	// duration	
	bindingOptions = [NSMutableDictionary dictionaryWithDictionary:defaultBindingOptions];
	[bindingOptions setObject:intervalTransformer forKey:NSValueTransformerBindingOption];	
	column = [_progressTable tableColumnWithIdentifier:@"duration"];
	[column bind:NSValueBinding toObject:_progressArrayController withKeyPath:@"arrangedObjects.duration" options:bindingOptions];

	// remaining time
	bindingOptions = [NSMutableDictionary dictionaryWithDictionary:defaultBindingOptions];
	/*intervalTransformer = [[MGSTimeIntervalTransformer alloc] init];
	intervalTransformer.resolution = MGSTimeSecond;
	intervalTransformer.style = MGSTimeStyleTextual;
	intervalTransformer.returnAttributedString = NO;
	[bindingOptions setObject:intervalTransformer forKey:NSValueTransformerBindingOption];*/
	column = [_progressTable tableColumnWithIdentifier:@"remaining"];
	[column bind:NSValueBinding toObject:_progressArrayController withKeyPath:@"arrangedObjects.remainingTimeString" options:bindingOptions];
	
	// transfer info
	bindingOptions = [NSMutableDictionary dictionaryWithDictionary:defaultBindingOptions];
	column = [_progressTable tableColumnWithIdentifier:@"information"];
	[column bind:NSValueBinding toObject:_progressArrayController withKeyPath:@"arrangedObjects.progressString" options:bindingOptions];
	
	// progress complete
	bindingOptions = [NSMutableDictionary dictionaryWithDictionary:defaultBindingOptions];
	column = [_progressTable tableColumnWithIdentifier:@"progress"];
	[column bind:NSValueBinding toObject:_progressArrayController withKeyPath:@"arrangedObjects.percentageComplete" options:bindingOptions];
	[column bind:NSMaxValueBinding toObject:_progressArrayController withKeyPath:@"arrangedObjects.maxProgress" options:nil];
	[column bind:NSMinValueBinding toObject:_progressArrayController withKeyPath:@"arrangedObjects.minProgress" options:nil];

	
	// action popup binding options
	// define a null placeholder value to go at start of popup list
	bindingOptions = [NSDictionary dictionaryWithObjectsAndKeys:
						  [NSNumber numberWithBool:YES], NSInsertsNullPlaceholderBindingOption,
						  NSLocalizedString(@"<None>", @"Result none placeholder - appears in result popup menu"), NSNullPlaceholderBindingOption, nil];
	
	// action popup bindings
	[_resultActionPopup bind:NSContentBinding toObject:_resultController withKeyPath:@"arrangedObjects" options:nil];
	[_resultActionPopup bind:NSContentValuesBinding toObject:_resultController withKeyPath:@"arrangedObjects.action.nameWithParameterValues" options:bindingOptions];
	[_resultActionPopup bind:NSSelectedIndexBinding toObject:_resultController withKeyPath:@"selectionIndex" options:nil];
	
	// bind the pre and next result buttons
	[showPrevResult bind:NSEnabledBinding toObject:self withKeyPath:@"showPrevResultEnabled" options:nil];
	[showNextResult bind:NSEnabledBinding toObject:self withKeyPath:@"showNextResultEnabled" options:nil];

	// bind the sync result button
	bindingOptions = [NSDictionary dictionaryWithObjectsAndKeys:[NSValueTransformer valueTransformerForName:NSNegateBooleanTransformerName], NSValueTransformerBindingOption, nil];
	[syncResultButton bind:NSEnabledBinding toObject:self withKeyPath:@"indexMatchesPartnerIndex" options:bindingOptions];
	//[syncResultButton bind:@"enabled2" toObject:self withKeyPath:@"taskResultDisplayLocked" options:bindingOptions];

	// position text
	NSString *format = NSLocalizedString(@"%i of %i", @"Result count format");
	bindingOptions = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSString stringWithFormat:format, 0, 0], NSNullPlaceholderBindingOption, nil];
	[positionTextField bind:NSValueBinding toObject:self withKeyPath:@"resultPositionString" options:bindingOptions];
	
	// task result lock button
	[taskResultLockButton bind:NSValueBinding toObject:self withKeyPath:@"taskResultDisplayLocked" options:nil];
	
	// result observing
	[_resultController addObserver:self forKeyPath:@"selectionIndex" options:NSKeyValueObservingOptionNew context:MGSResultSelectionIndexContext]; 
	
	// result view observing
	//[_resultViewController addObserver:self forKeyPath:@"showNextViewModeToggle" options:0 context:MGSShowNextViewModeContext]; 
	//[_resultViewController addObserver:self forKeyPath:@"showPrevViewModeToggle" options:0 context:MGSShowPrevViewModeContext]; 
	[_resultViewController addObserver:self forKeyPath:@"viewMode" options:0 context:MGSViewModeContext]; 
	
	// image view to use for drag thumb
	[_resultViewController setDragThumbView:[[MGSImageManager sharedManager] imageView:[[[MGSImageManager sharedManager] splitDragThumbVert] copy]]];

	// read preferences
	self.taskResultDisplayLocked = [[NSUserDefaults standardUserDefaults] boolForKey:MGSTaskResultDisplayLocked];
	
	[self updateIndexMatchesPartnerIndex];
	
}

/*
 
 finalize
 
 */
- (void) finalize
{
	MLog(DEBUGLOG, @"finalized");
	[super finalize];
}

#pragma mark -
#pragma mark Action
/*
 
 set the action specifier
 
 */
- (void)setAction:(MGSTaskSpecifier *)action
{
	// remove current observers
	if (_action.script) {
		@try {
			[_action removeObserver:self forKeyPath:@"runStatus"];
			[_action removeObserver:self forKeyPath:@"requestProgress.value"];
		} 
		@catch (NSException *e) {
			MLog(RELEASELOG, @"%@", [e reason]);
		}
	}
	
	_action = action;
	
	// activity view controller needs to know its initial run mode.
	// in order to determine this it requires netclient and window.
	//NSAssert([[self view] window], @"window is nil");
	//MGSNetClientContext *context = [[action netClient] contextForWindow:[[self view] window]];
	//NSAssert(context, @"client context is nil");
	//[_actionActivityViewController setRunMode:context.runMode];
	
	// add observers
	if (_action.script) {
		
		[_action addObserver:self 
			forKeyPath:@"runStatus" 
			options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld 
			context:MGSRunStatusContext];
		
		[_action addObserver:self 
			forKeyPath:@"requestProgress.value" 
			options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld 
			context:MGSActionProgressContext];
	}
	
	[self reset];
}

/*
 
 action input modified
 
 action input has been modifed.
 set the activity to ready and clear any visible results.
 
 */
- (void)actionInputModified
{
	if (!self.action.netClient.isConnected) {
		return;
	}
	
	_actionActivityViewController.activity = MGSReadyTaskActivity;
    [_actionActivityViewController clearDisplayString];
	[self setResultsAvailableForAction:NO];
	[self resetRequestProgress];
}

#pragma mark -
#pragma mark Results
/*
 
 set results available for action
 
 
 if results available for the action then show the result view.
 if not, show the action activity view.
 
 */
- (void)setResultsAvailableForAction:(BOOL)value
{
	_resultsAvailableForAction = value;
	
	// if results available show the result view, otherwise show the action activity view
	NSView *newView;
	if (_resultsAvailableForAction) {
		newView = [_resultViewController view];
	} else {
		newView = [_actionActivityViewController view];
		[_resultController setSelectedObjects:nil];		// setting nil here will display bound nul placeholder
	}
	        
    [_actionActivityViewController clearDisplayString];
    
	if (resultView != newView) {
		[splitView replaceSubview:resultView withViewFrameAsOld:newView];
        resultView = newView;
        
		[viewModeSegmentedControl setEnabled:_resultsAvailableForAction];
		[detachWindowButton setEnabled:_resultsAvailableForAction];
		self.indexMatchesPartnerIndex = _resultsAvailableForAction;
	}
}

/*
 
 add result
 
 */
- (void)addResult:(MGSResult *)result
{
	//
	// simply retain the result
	//
	
	//
	// add result to result controller
	//
	result.progressArray = [[_progressArrayController content] copy];
	[_resultController addObject:result];
	
	// check result object class for action
	NSInteger newViewModeSegment = -1;
	NSInteger viewModeSegment = [viewModeSegmentedControl selectedSegment];
	NSInteger defaultViewModeSegment = SEG_DOCUMENT;
	
	// if result is an error then show the list view as this
	// gives the clearest insight into what has occurred
	if ([result.object isKindOfClass:[NSError class]]) {
		newViewModeSegment = SEG_LIST;
		
		// if we have attachments then show the icon view
	} else if ([result.attachments count] > 0) {
		newViewModeSegment = SEG_ICON;
		
		// so no errors and no attachments
	} else {
		switch (viewModeSegment) {
			case SEG_LIST:
				break;
				
			case SEG_ICON:
				newViewModeSegment = defaultViewModeSegment;
				break;
				
			case SEG_DOCUMENT:
				break;
				
			case SEG_SCRIPT:
				break;
				
			default:
				NSAssert(NO, @"invalid view mode segment");
				break;
		}
	}
	
	
	// set segment selection state and call click action
	if (newViewModeSegment > -1) {
		[self selectViewSegment:newViewModeSegment];
	}
		 
	self.resultsAvailableForAction = YES;
}

/* 
 
 show previous result
 
 */
- (IBAction)showPreviousResult:(id)sender
{
	#pragma unused(sender)
	
	NSInteger idx = [_resultController selectionIndex];
	if (idx == NSNotFound) {	
		if ([[_resultController arrangedObjects] count] > 0) {
			idx = [[_resultController arrangedObjects] count] - 1;	// get out of ready state
		}
	} else if (idx != NSNotFound && idx >0) {
		idx--;
	}
	[self setSelectedResultIndex:idx];
	
}

/* 
 
 show next result
 
 */
- (IBAction)showNextResult:(id)sender
{
	#pragma unused(sender)
	
	NSUInteger idx = [_resultController selectionIndex];
	
	if (idx == NSNotFound) {
		idx = 0;	// get out of ready state into first result
	}else if (idx < [[_resultController arrangedObjects] count] - 1) {
		idx++;
	}
	[self setSelectedResultIndex:idx];
}

#pragma mark -
#pragma mark Action/result partners

/*
 
 set selected partner index
 
 */
- (void)setSelectedPartnerIndex:(NSInteger)idx
{
	_selectedPartnerIndex = idx;
	
	// if display locked with partner then change
	if (self.taskResultDisplayLocked || _selectedPartnerIndex == NSNotFound) {
		if ([self selectedResultIndex] != self.selectedPartnerIndex) {
			[self setSelectedResultIndex:self.selectedPartnerIndex];
		}
	} 
	
	[self updateIndexMatchesPartnerIndex];
}


/*
 
 sync partner selected index
 
 */
- (IBAction)syncPartnerSelectedIndex:(id)sender
{
	#pragma unused(sender)
	
	if ([[self delegate] respondsToSelector:@selector(syncPartnerSelectedIndex:)]) {
		[[self delegate] syncPartnerSelectedIndex:self];
	}
}

/*
 
 sync to partner selected index
 
 */
-(void)syncToPartnerSelectedIndex
{
	[self setSelectedResultIndex:self.selectedPartnerIndex];
}

/*
 
 set index matches partner index
 
 */
- (void)setIndexMatchesPartnerIndex:(BOOL)value
{
	_indexMatchesPartnerIndex = value;
	
	NSColor *textColor;
	
	// if menu tagged then clear out any attributed titles
	if ([_resultActionPopup tag] == NSNotFound) {
		for (int i=0; i < [_resultActionPopup numberOfItems]; i++) {
			[[_resultActionPopup itemAtIndex:i] setAttributedTitle:nil];
		}
	}
	
	// if our index does not match the partner index then
	// display the selected index item in red to indicate that the displayed result
	// does not match displayed action
	if (_indexMatchesPartnerIndex) {
		[_resultActionPopup setTag:0];
		textColor = [NSColor blackColor];
	} else {
		textColor = [NSColor redColor];
		
		NSMenuItem *menuItem = [_resultActionPopup selectedItem];
		
		// paragraph style is required to get attributed string to truncate
		NSMutableParagraphStyle *truncateStyle = [[NSMutableParagraphStyle alloc] init];
        [truncateStyle setLineBreakMode:NSLineBreakByTruncatingTail];
		
		NSDictionary *attributes = [NSDictionary
									dictionaryWithObjectsAndKeys:
									textColor, NSForegroundColorAttributeName,
									truncateStyle, NSParagraphStyleAttributeName,
									[_resultActionPopup font],
									NSFontAttributeName, nil];
		
		NSAttributedString *attributedTitle =[[NSAttributedString alloc] initWithString:[menuItem title] attributes:attributes];
		[menuItem setAttributedTitle:attributedTitle];
		
		[_resultActionPopup setTag:NSNotFound];
	}
	
	[positionTextField setTextColor:textColor];
}

#pragma mark -
#pragma mark Navigation bar
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
	int mode = kMGSMotherResultViewDocument;	
	switch (selectedSegment) {
		case SEG_LIST:
			mode = kMGSMotherResultViewList;
			break;

		case SEG_ICON:
			mode = kMGSMotherResultViewIcon;
			break;
			
		case SEG_DOCUMENT:
			mode = kMGSMotherResultViewDocument;
			break;
			
		case SEG_SCRIPT:
			mode = kMGSMotherResultViewScript;
			break;
			
		default:
			NSAssert(NO, @"bad segment");
			return;
			
	}
	
	_resultViewController.viewMode = mode;	
}


/*
 
 set task result display locked
 
 */
- (void)setTaskResultDisplayLocked:(BOOL)value
{
	_taskResultDisplayLocked = value;
	// save as preference
	[[NSUserDefaults standardUserDefaults] setBool:_taskResultDisplayLocked forKey:MGSTaskResultDisplayLocked];
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
	
	// result selection index changed
	if (context == MGSResultSelectionIndexContext) {
		
		NSInteger resultCount = [[_resultController arrangedObjects] count];
		NSInteger resultIndex = [_resultController selectionIndex];
		BOOL showPrevResultEnabled = YES,  showNextResultEnabled = YES;

		
		// set state of prev/next result buttons
		if (resultCount == 0) {
			showPrevResultEnabled = NO;
			showNextResultEnabled = NO;
		}
		
		if (resultIndex == 0 ) {
			showPrevResultEnabled = NO;
		}

		if (resultIndex == resultCount - 1) {
			showNextResultEnabled = NO;
		}

		// if no object selected in the array controller then index is NSNotFound
		if (resultIndex == NSNotFound && resultCount > 0) {
			showPrevResultEnabled = YES;
			showNextResultEnabled = NO;
		} 
		
		// these are bound to buttons
		self.showPrevResultEnabled = showPrevResultEnabled;
		self.showNextResultEnabled = showNextResultEnabled;
		
		// set the position string
		NSString *format = NSLocalizedString(@"%i of %i", @"Result count format");
		self.resultPositionString = [NSString stringWithFormat:format, resultIndex == NSNotFound ? 0 : resultIndex + 1, resultCount];
		
		MGSResult *result = nil;
		
		if (resultIndex != NSNotFound) {
			
			// get selected result
			result = [[_resultController arrangedObjects] objectAtIndex:resultIndex];
			
			// view the result
			[_resultViewController setResult:result];

			// view the result progress for result.
			// note that we probably don't want to modify this but it make it mutable anyway
			[_progressArrayController setContent:[NSMutableArray arrayWithArray:result.progressArray]];
			
			[self setResultsAvailableForAction:YES];

		} else {
			[self setResultsAvailableForAction:NO];
		}
		
		[self updateIndexMatchesPartnerIndex];
		
		[self willChangeValueForKey:@"selectedIndex"];
		_selectedIndex = resultIndex;
		[self didChangeValueForKey:@"selectedIndex"];

		// restore last view mode for result
		if (result) {
			[self selectViewSegment:[self segmentIndexForViewMode:result.viewMode]];
		}

	}
	
	// run status context
	else if (context == MGSRunStatusContext) {
		
		NSAssert(change, @"change dictionary not defined");
		NSNumber *prevNumber = [change objectForKey:NSKeyValueChangeOldKey];
		NSAssert(prevNumber, @"previous status not defined");
		MGSTaskRunStatus prevStatus = [prevNumber intValue];
		
		switch (_action.runStatus) {
			case MGSTaskRunStatusReady:
				break;

			case MGSTaskRunStatusHostUnavailable:
				break;

			case MGSTaskRunStatusExecuting:
				
				// executing state may get reset when resuming
				if (prevStatus != MGSTaskRunStatusSuspended &&
					prevStatus != MGSTaskRunStatusSuspendedSending &&
					prevStatus != MGSTaskRunStatusSuspendedReceiving
					) {
					
					[self setResultsAvailableForAction:NO];	// no results available
					[self reset];
				
					// disable controls while processing
					[_controlStripView setControlsEnabled:NO];
				}
				break;
				
			case MGSTaskRunStatusSuspended:
			case MGSTaskRunStatusSuspendedSending:
			case MGSTaskRunStatusSuspendedReceiving:
				break;

			case MGSTaskRunStatusComplete:
			case MGSTaskRunStatusCompleteWithError:
			case MGSTaskRunStatusTerminatedByUser:
				// enable controls after processing
				[_controlStripView setControlsEnabled:YES];
				break;
				
			default:
				NSAssert(NO, @"invalid run status");
		}
		
		// update
		[self updateActivity];
	}
	
	// acion progress context
	else if (context == MGSActionProgressContext) {
		
		// action progress has changed.
		[self setRequestProgress:[self action].requestProgress.value];
	}
	
	// progress context
	else if (context == MGSProgressDurationContext) {
		
		// progress duration updated
		[_action.netRequest updateProgress:[self progress]];

	// view mode
	} else if (context == MGSViewModeContext) {
		
		// set view mode selected segment to match result view mode
		[viewModeSegmentedControl setSelectedSegment:[_resultViewController viewMode]];
	}
}

#pragma mark -
#pragma mark Tasklogging
/*
 
 - addLogString:
 
 */
- (void)addLogString:(NSString *)value {
    [_resultViewController addLogString:value];
    
    [_actionActivityViewController addDisplayString:value];
}

#pragma mark -
#pragma mark Progress
/*
 
 set request progress
 
 */
- (void)setRequestProgress:(eMGSRequestProgress)value
{
	[self setRequestProgress:value object:nil];
}

/*
 
 set request progress object
 
 */
- (void)setRequestProgress:(eMGSRequestProgress)value object:(id)object
{
	MGSRequestProgress *progress = [_progressArrayController newObject];
	progress.delegate = self;
	progress.overviewString = [_action displayName];
	
	[progress setValue:value object:object];
	[self addProgress:progress];
}

/*
 
 progress
 
 returns the current progress object
 
 */
- (MGSRequestProgress *)progress
{
	return [[_progressArrayController arrangedObjects] lastObject];
}

/*
 
 refresh progress display
 
 */
- (void)progressDisplay
{
	[_progressTable display];
}

#pragma mark -
#pragma mark Window handling
/*
 
 detach result into another window
 
 */
- (IBAction)detachResultAsWindow:(id)sender
{
	#pragma unused(sender)
	// open copy of result in another window
	MGSResult *result = [_resultViewController result];
	
#pragma mark warning do we need a copy of the result data here?
	
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:_resultViewController.viewConfig], MGSNoteViewConfigKey, nil];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteOpenResultInWindow object:result
													  userInfo:userInfo];
}

/*
 
 can detach result as window
 
 */
- (BOOL)canDetachResultAsWindow
{
	if (![detachWindowButton isHidden] && [detachWindowButton isEnabled]) {
		return YES;
	}

	return NO;
}

#pragma mark -
#pragma mark MGSRequestProgress delegate methods

/*
 
 request progress updated
 
 */
- (void)requestProgressUpdated:(MGSRequestProgress *)sender
{
	_action.requestProgress.overviewString = sender.overviewString;
}

#pragma mark -
#pragma mark NSSplitView delegate methods

//
// size splitview subviews as required
//
- (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize: (NSSize)oldSize
{	
	MGSSplitviewBehaviour behaviour;
	
	/*
	if ([sender isEqual:windowSplitView]) {
		behaviour = MGSSplitviewBehaviourOf2ViewsFirstFixed;
	} else {
		NSAssert(NO, @"invalid splitview");
	}
	*/
	
	behaviour = MGSSplitviewBehaviourOf2ViewsSecondFixed;
	
	// see the NSSplitView_Mugginsoft category
	[sender resizeSubviewsWithOldSize:oldSize withBehaviour:behaviour];
}

/*
 
 get additional rect to be used to drag splitview
 
 */
- (NSRect)splitView:(NSSplitView *)aSplitView additionalEffectiveRectOfDividerAtIndex:(NSInteger)dividerIndex
{
	#pragma unused(dividerIndex)
	
	//NSView *subView = [[aSplitView subviews] objectAtIndex:dividerIndex];
	
	// rect must be in splitview co-ords
	//NSRect rect = [_resultViewController splitViewRect];
	NSView *additionalView;
	if (resultView == [_resultViewController view]) {
		additionalView = [_resultViewController splitViewAdditionalView];
	} else {
		additionalView = [_actionActivityViewController splitViewAdditionalView];
	}
	return [aSplitView convertRect:[additionalView bounds] fromView:additionalView];
}

/*
 
 splitview constrain split position
 
 */
- (CGFloat)splitView:(NSSplitView *)sender constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)offset
{
	#pragma unused(offset)
	
	CGFloat tableViewMaxHeight = ([_progressTable rowHeight] + [_progressTable intercellSpacing].height) * 6 + [[_progressTable headerView] frame].size.height;
	CGFloat minHeight = [sender frame].size.height - tableViewMaxHeight;
	
	// min height
	if (proposedPosition < minHeight) {
		proposedPosition = minHeight;
	} 
	
	return proposedPosition;
}

#pragma mark -
#pragma mark NSView delegate methods

/*
 
 view did move to window
 
 */
- (void)view:(NSView *)aView didMoveToWindow:(NSWindow *)aWindow
{
	if (aWindow && aView == [self view] && _action) {
		
		// activity view controller needs to know its initial run mode.
		// in order to determine this it requires netclient and window.
		MGSNetClientContext *context = [[_action netClient] contextForWindow:aWindow];
		
		// context may not yet be defined for window
		if (context) {
			[_actionActivityViewController setRunMode:context.runMode];
		}
	}
	
}
@end


@implementation MGSOutputRequestViewController(Private)

#pragma mark Reset
/*
 
 reset
 
 */
- (void)reset
{
	[self updateActivity];
	[self setResultsAvailableForAction:NO];
	[self resetRequestProgress];
}

/*
 
 reset progress
 
 */
- (void)resetRequestProgress
{
	// only reset if connected
	if (self.action.netClient.isConnected) {	
		[_progressArrayController setContent:[NSMutableArray arrayWithCapacity:5]];
		[self setRequestProgress:MGSRequestProgressReady];
	}
}

#pragma mark -
#pragma mark Result view
/*
 
 select view segment
 
 */
- (void)selectViewSegment:(NSInteger)idx
{
	[viewModeSegmentedControl setSelectedSegment:idx];
	[self segmentClick:idx];
}
/*
 
 get segment index for view mode
 
 */
- (NSInteger)segmentIndexForViewMode:(eMGSMotherResultView)viewMode
{
	NSInteger idx = -1;
	
	switch (viewMode) {
		case kMGSMotherResultViewList:
			idx = SEG_LIST;
			break;
			
		case kMGSMotherResultViewIcon:
			idx = SEG_ICON;
			break;
			
		case kMGSMotherResultViewDocument:
			idx = SEG_DOCUMENT;
			break;
			
		case kMGSMotherResultViewScript:
			idx = SEG_SCRIPT;
			break;
			
		default:
			NSAssert(NO, @"bad view mode");
			break;
	}
	
	return idx;
}

#pragma mark -
#pragma mark Progress
/*
 
 add progress
 
 */
- (void)addProgress:(MGSRequestProgress *)progress
{
	// stop timimg the current request progress
	MGSRequestProgress *prevProgress = [self progress];
	if (prevProgress) {
		[prevProgress stopDurationTimer];
		
		// mark prev progress as complete
		switch (progress.value) {
				
			case MGSRequestProgressSuspended:
			case MGSRequestProgressSuspendedSending:
			case MGSRequestProgressSuspendedReceiving:
			case MGSRequestProgressCompleteWithErrors:
			case MGSRequestProgressTerminatedByUser:
				break;
				
			default:
				prevProgress.complete = YES;
				break;
		}
		
		// remove observers
		@try {
			[_observedProgress removeObserver:self forKeyPath:@"duration"];
			_observedProgress = nil;
		} 
		@catch (NSException *e) {
			MLog(RELEASELOG, @"%@", [e reason]);
		}
	}
	
	// add new progress item
	[_progressArrayController addObject:progress];
	[_progressTable scrollRowToVisible:[_progressTable numberOfRows] -1];
	_observedProgress = progress;
	[_observedProgress addObserver:self forKeyPath:@"duration" options:0 context:MGSProgressDurationContext];
	
	switch (progress.value) {
		
		// sending
		case MGSRequestProgressSending:
			if (_suspendedProgress && _suspendedProgress.value == progress.value) {
				[progress restartDurationTimer:_suspendedProgress];
			} else {
				progress.requestSizeTotal = _action.netRequest.requestMessage.totalBytes;
				[progress startDurationTimer];
			}
			_suspendedProgress = nil;
			break;

		// receiving
		case MGSRequestProgressReceivingReply:
			if (_suspendedProgress && _suspendedProgress.value == progress.value) {
				[progress restartDurationTimer:_suspendedProgress];
			} else {
				progress.requestSizeTotal = [_action.netRequest.responseMessage totalBytesFromHeader];
				[progress startDurationTimer];
			}
			_suspendedProgress = nil;
			break;

		// suspending
		case MGSRequestProgressSuspendedSending:
		case MGSRequestProgressSuspendedReceiving:
			_suspendedProgress = prevProgress;
			[progress startDurationTimer];
			break;
			

		// time the duration of these
		case MGSRequestProgressWaitingForReply:
		case MGSRequestProgressSuspended:
			[progress startDurationTimer];
			break;
			
		case MGSRequestProgressReplyReceived:
			break;
			
		case MGSRequestProgressCompleteWithNoErrors:
		case MGSRequestProgressCompleteWithErrors:
		case MGSRequestProgressCannotConnect:
		case MGSRequestProgressTerminatedByUser:
			// duration is sum total of previous durations
			[progress setDuration:[self progressDuration]];
			_action.elapsedTime = [progress duration];
			progress.complete = YES;
			@try {
				[progress removeObserver:self forKeyPath:@"duration"];
				_observedProgress = nil;
			} 
			@catch (NSException *e) {
				MLog(RELEASELOG, @"%@", [e reason]);
			}
			_suspendedProgress = nil;
			break;
			
		default:
			break;

	}
}

/*
 
 duration of progress
 
 */
- (NSTimeInterval)progressDuration
{	
	NSTimeInterval duration = 0;
	
	for (MGSRequestProgress *progress in [_progressArrayController arrangedObjects]) {
		if (progress.duration >= 0) {
			//MLog(DEBUGLOG, @"duration before: %f", [progress duration]);
			// round our progress to reqd resolution
			NSTimeInterval interval = [MGSTimeIntervalTransformer timeInterval:[progress duration] withResolution: _progressTimeResolution];
			//MLog(DEBUGLOG, @"duration after: %f", interval);
			duration += interval;
		}
	}
	MLog(DEBUGLOG, @"total duration: %f", duration);
	
	return duration;
}

#pragma mark -
#pragma mark Activity
/*
 
 update activity
 
 */
- (void)updateActivity
{
	_actionActivityViewController.activity = _action.activity;
}

#pragma mark -
#pragma mark Results
/*
 
 index of currently selected result
 
 */
- (NSInteger)selectedResultIndex
{
	return [_resultController selectionIndex];
}
/*
 
 set index of currently selected result
 
 */
- (void)setSelectedResultIndex:(NSInteger)idx
{
	if (idx == NSNotFound) {
		[self setResultsAvailableForAction:NO];
	} else {
		if (idx >=0 && idx < (NSInteger)[[_resultController arrangedObjects] count]) {
			[_resultController setSelectionIndex:idx];
			[self setResultsAvailableForAction:YES];
		} else {
			// The following log function does get called.
			// Unsure what the significance of it is though.
			//MLog(RELEASELOG, @"invalid result index requested");
		}
	}
	
	[self updateIndexMatchesPartnerIndex];
}
#pragma mark -
#pragma mark Action/result partners
/*
 
 update index matches partner index
 
 */
- (void)updateIndexMatchesPartnerIndex
{
	self.indexMatchesPartnerIndex = ([self selectedResultIndex] == self.selectedPartnerIndex) ? YES : NO;
}
@end
