//
//  MGSInputRequestViewController.m
//  Mother
//
//  Created by Jonathan on 05/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSInputRequestViewController.h"
#import "MGSRequestViewController.h"
#import "MGSParameterViewManager.h"
#import "MGSActionViewController.h"
#import "MGSScript.h"
#import "MGSTaskSpecifier.h"
#import "MGSNotifications.h"
#import "MGSTaskSpecifierManager.h"
#import "MGSGradientView.h"
#import "MGSParameterSplitView.h"
#import "NSView_Mugginsoft.h"
#import "MGSNullBindingProxy.h"
#import "MGSNotifications.h"
#import "MGSPreferences.h"
#import "MGSAttachedWindowController.h"
#import "MGSScriptParameterManager.h"

NSString *MGSIsProcessingContext =@"IsProcessing";
static NSString *MGSActionSelectionIndexContext = @"MGSActiontSelectionIndexContext";

// class extension
@interface MGSInputRequestViewController()
- (void)initialiseAction:(NSNotification *)note;
@end

@interface MGSInputRequestViewController(Private)
- (NSInteger)selectedActionIndex;
- (void)setSelectedActionIndex:(NSUInteger)index;
- (void)updateIndexMatchesPartnerIndex;
- (void)markAsReadyIfNoResults;
@end

#pragma mark -
#pragma mark Properties
@implementation MGSInputRequestViewController
@synthesize delegate = _delegate;
@synthesize action = _action;
@synthesize actionViewController = _actionViewController;
@synthesize allowDetach = _allowDetach;
@synthesize allowLock = _allowLock;
@synthesize keepActionDisplayed = _keepActionDisplayed;
@synthesize showPrevActionEnabled = _showPrevActionEnabled;
@synthesize showNextActionEnabled = _showNextActionEnabled;
@synthesize actionPositionString = _actionPositionString;
@synthesize actionController = _actionController;
@synthesize indexMatchesPartnerIndex = _indexMatchesPartnerIndex;
@synthesize taskResultDisplayLocked = _taskResultDisplayLocked;
@synthesize selectedPartnerIndex = _selectedPartnerIndex;
@synthesize selectedIndex = _selectedIndex;
@synthesize isProcessing = _isProcessing;

#pragma mark -
#pragma mark Instance control

/* 
 
 awake from nib
 
 */
- (void)awakeFromNib
{
	_selectedPartnerIndex = NSNotFound;
	_selectedIndex = NSNotFound;
	_indexMatchesPartnerIndex = YES;
	_isProcessing = NO;
	//_keepActionDisplayed = [[NSUserDefaults standardUserDefaults] boolForKey:MGSNewTabKeepTaskDisplayed];
	_keepActionDisplayed = NO;
	
	[lockButton setHidden:NO];
	[detachButton setHidden:NO];

	_actionController = [[MGSTaskSpecifierManager alloc] init];

	[scrollView setBackgroundColor:[MGSGradientView endColor]];
	
	_showNextActionEnabled = NO;
	_showPrevActionEnabled = NO;
	_actionPositionString = @"";
	
	// establish bindings
	
	// action popup binding options
	// define a null placeholder value to go at start of popup list
	NSDictionary *bindingOptions = nil;
	bindingOptions = [NSDictionary dictionaryWithObjectsAndKeys:
						[NSNumber numberWithBool:YES], NSInsertsNullPlaceholderBindingOption,
						NSLocalizedString(@"<Run task...>",@"Task ready placeholder - appears in task popup menu"), NSNullPlaceholderBindingOption, nil];
	
	// action popup
	[_actionPopup bind:NSContentBinding toObject:_actionController withKeyPath:@"arrangedObjects" options:nil];
	[_actionPopup bind:NSContentValuesBinding toObject:_actionController withKeyPath:@"arrangedObjects.nameWithParameterValues" options:bindingOptions];
	[_actionPopup bind:NSSelectedIndexBinding toObject:_actionController withKeyPath:@"selectionIndex" options:nil];
	
	// bind the pre and next action buttons
	[showPrevAction bind:NSEnabledBinding toObject:self withKeyPath:@"showPrevActionEnabled" options:nil];
	[showNextAction bind:NSEnabledBinding toObject:self withKeyPath:@"showNextActionEnabled" options:nil];
	
	// position text
	NSString *format = NSLocalizedString(@"%i of %i", @"Task count format");
	bindingOptions = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSString stringWithFormat:format, 0, 0], NSNullPlaceholderBindingOption, nil];
	[positionTextField bind:NSValueBinding toObject:self withKeyPath:@"actionPositionString" options:bindingOptions];
	
	/*
     In order for the binding to take NSToggleButton must be set.
     In order for the template to be highlighted in the on state NSBackgroundStyleRaised
     must be applied.
     */
    
    // configure toggle button which highlights template image in On state
    [[lockButton cell] setButtonType:NSToggleButton];
    [[lockButton cell] setBackgroundStyle:NSBackgroundStyleRaised];
    [lockButton setFocusRingType:NSFocusRingTypeNone];
    [lockButton setBezelStyle:NSRoundRectBezelStyle];
    [lockButton setBordered:NO];
    
	[lockButton bind:NSValueBinding toObject:self withKeyPath:@"keepActionDisplayed" options:nil];

#ifdef MGS_DEBUG_BUTTON_STATE
    
    NSLog(@"LockButton showsStateBy: %d showsHighlightsBy: %d bezelStyle: %d backgroundStyle: %d interiorBackgroundStyle: %d", 
            [[lockButton cell] showsStateBy], 
            [[lockButton cell] highlightsBy], 
            [[lockButton cell] bezelStyle],
            [[lockButton cell] backgroundStyle],
            [[lockButton cell] interiorBackgroundStyle]);
    
#endif
    
	// bind the sync result button
	bindingOptions = [NSDictionary dictionaryWithObjectsAndKeys:[NSValueTransformer valueTransformerForName:NSNegateBooleanTransformerName], NSValueTransformerBindingOption, nil];
	[syncActionButton bind:NSEnabledBinding toObject:self withKeyPath:@"indexMatchesPartnerIndex" options:bindingOptions];
	
	// observing
	[_actionController addObserver:self forKeyPath:@"selectionIndex" options:NSKeyValueObservingOptionNew context:MGSActionSelectionIndexContext]; 
	
	// set the parameter view handler to input mode
	[_parameterViewManager setMode:MGSParameterModeInput];
	
	// notification observers
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(initialiseAction:) name:MGSNoteInitialiseAction object:nil];
	
	[self updateIndexMatchesPartnerIndex];
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
	
	// action selection index
	if (context == MGSActionSelectionIndexContext) {
		
		NSInteger actionIndex = [_actionController selectionIndex];
		NSInteger actionCount = [[_actionController arrangedObjects] count];
		
		BOOL showPrevActionEnabled = YES,  showNextActionEnabled = YES;

		
		if (actionCount == 0) {
			showPrevActionEnabled = NO;
			showNextActionEnabled = NO;
		}
		
		if (actionIndex == 0) {
			showPrevActionEnabled = NO;
		}
		
		if (actionIndex == actionCount - 1) {
			showNextActionEnabled = NO;
		}
	
		// if no object selected in the array controller then index is NSNotFound
		if (actionIndex == NSNotFound && actionCount > 0) {
			showPrevActionEnabled = YES;
			showNextActionEnabled = NO;
		} 
		
		self.showPrevActionEnabled = showPrevActionEnabled;
		self.showNextActionEnabled = showNextActionEnabled;
		
		// set position string
		NSString *format = NSLocalizedString(@"%i of %i", @"Task count format");
		self.actionPositionString = [NSString stringWithFormat:format, actionIndex == NSNotFound ? 0 : actionIndex + 1, actionCount];
		
		if (actionIndex != NSNotFound) {
			
			// get selected action
			MGSTaskSpecifier *action = [[_actionController arrangedObjects] objectAtIndex:actionIndex];
			
			// we don't want to modify our completed actions so make a copy and assign the current result.
			// if the action is modified then we merely discard the current result.
			MGSTaskSpecifier *actionCopy = [action mutableDeepCopyAsExistingInstance];
			actionCopy.result = action.result;
			
			// view the action
			[self setAction:actionCopy];
			
		} else {
			_action.result = nil;
		}	
		
		[self markAsReadyIfNoResults];
		[self updateIndexMatchesPartnerIndex];
		
		[self willChangeValueForKey:@"selectedIndex"];
		_selectedIndex = actionIndex;
		[self didChangeValueForKey:@"selectedIndex"];
		
	}
	
	// action is processing
	else if (context == MGSIsProcessingContext) {
		
		// disable controls while processing
		[[self view] setControlsEnabled:!_action.isProcessing];
		
		self.isProcessing = _action.isProcessing;
			
		// hightlight action view
		[_parameterViewManager highlightActionView];
	
	} 
}

#pragma mark -
#pragma mark Result partner handling
/*
 
 sync to partner selected index
 
 */
-(void)syncToPartnerSelectedIndex
{
	[self setSelectedActionIndex:self.selectedPartnerIndex];
}

/*
 
 set selected partner index
 
 */
- (void)setSelectedPartnerIndex:(NSInteger)idx
{

	_selectedPartnerIndex = idx;
	
	// if display locked with partner then change
	if (self.taskResultDisplayLocked || _selectedPartnerIndex == NSNotFound) {
		if ([self selectedActionIndex] != self.selectedPartnerIndex) {
			[self setSelectedActionIndex:self.selectedPartnerIndex];
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

#pragma mark -
#pragma mark Action selection
/*
 
 action input modified
 
 action input has been modifed.
 set the activity to ready and clear any visible results.
 
 */
- (void)actionInputModified
{
	// if input modified then mark result as invalid
	if (_action.result) {
		_action.result = nil;
	}
	
	[self markAsReadyIfNoResults];
}

/*
 
 set the action
 
 */
- (void)setAction:(MGSTaskSpecifier *)action
{
	if (_action.script) {
		@try {
			[_action removeObserver:self forKeyPath:@"isProcessing"];
		} 
		@catch (NSException *e) {
			MLog(RELEASELOG, @"%@", [e reason]);
		}
	}
	
	//NSAssert(action, @"action is nil");
	_action = action;
	
	// if script is nil then action represents no tasks available
	if (_action.script) {
		
		// create action view controller and view
		// note that the view controller also loads in a lazy manner, like NSWindowController.
		// to get it to actually load the nib be sure to access -view.
		_actionViewController = [[MGSActionViewController alloc] init];
		_actionViewController.delegate = self;
		[_actionViewController view];	// load the nib
		_actionViewController.action = _action;
		
		// _parameterViewHandler will co-ordinate the creation of the
		// required parameter views.
		// _parameterViewHandler will display the action view above the parameters
		_parameterViewManager.actionViewController = _actionViewController;
		
		// setting NSKeyValueObservingOptionInitial causes view enabling override bug
		[_action addObserver:self forKeyPath:@"isProcessing" options:0 context:MGSIsProcessingContext];
		
		[self markAsReadyIfNoResults];
		
		// hightlight action view
		[_parameterViewManager highlightActionView];

	}
}

/*
 
 show previous action
 
 */
- (IBAction)showPreviousAction:(id)sender
{
	#pragma unused(sender)
	
	NSInteger idx = [_actionController selectionIndex];
	if (idx == NSNotFound) {
		if ([[_actionController arrangedObjects] count] > 0) {
			idx = [[_actionController arrangedObjects] count] - 1;	// get out of ready state into last action
		}
	} else if (idx != NSNotFound && idx >0) {
		idx--;
	}
	[self setSelectedActionIndex:idx];
}

/*
 
 show next action
 
 */
- (IBAction)showNextAction:(id)sender
{
	#pragma unused(sender)
	
	NSUInteger idx = [_actionController selectionIndex];

	if (idx == NSNotFound) {
		idx = 0;	// get out of ready state into first action
	} else if (idx < [[_actionController arrangedObjects] count] - 1) {
		idx++;
	}
	
	[self setSelectedActionIndex:idx];
}

#pragma mark -
#pragma mark Notification callbacks
/*
 
 initialise action notification
 
 this merely sets the selected action + result to NULL first entry
 
 */
- (void)initialiseAction:(NSNotification *)note
{
	id object = [note object];
	if (![object isKindOfClass:[NSView class]]) return;
	
	if ([(NSView *)object isDescendantOf:[self view]]) {
		[self setSelectedActionIndex:NSNotFound];
	}
}

#pragma mark -
#pragma mark Interface handling

/*
 
 set task result display locked
 
 */
- (void)setTaskResultDisplayLocked:(BOOL)value
{
	if (value == YES) {
		[self setSelectedActionIndex:self.selectedPartnerIndex];
	}
	_taskResultDisplayLocked = value;
}

/*
 
 set allow lock
 
 */
- (void)setAllowLock:(BOOL)value
{
	[lockButton setHidden:!value];
}

/*
 
 set allow detach
 
 */
- (void)setAllowDetach:(BOOL)value
{
	[detachButton setHidden:!value];
}

#pragma mark -
#pragma mark Parameter handling
/*
 
 reset all parameters to default values
 
 */
- (void)resetToDefaultValue
{
	[_parameterViewManager resetToDefaultValue];
}

#pragma mark -
#pragma mark Can do operation
/*
 
 validate for execution
 
 */
- (BOOL)canExecute
{
	// there may be pending edits as bound NSTextFields will update
	// their bindings when they resign first responder.
	// An NSButton does not accept first responder and hence the NSTextField
	// does not update. Hence, the controller must implement the NSEditorRegistration
	// protocol to track such cases.
	if (![_parameterViewManager commitPendingEdits]) {
		MLog(DEBUGLOG, @"Could not commit pending edits");
		return NO;
	}
	
    // we can only execute if we have an execute epresentation
    if (![[_action script] canConformToRepresentation:MGSScriptRepresentationExecute]) {
        
        // get mouse click rect in window coordinate system
		NSWindow *window =[[self view] window];
        NSRect viewRect = [[window contentView] frame];
        
        NSEvent *event = [NSApp currentEvent];
        switch (event.type) {
            case NSLeftMouseUp:
                {
                    NSPoint eventPoint = [event locationInWindow];
                    NSPoint viewPoint = [[window contentView] convertPoint:eventPoint fromView:nil];
                    viewRect = NSMakeRect(viewPoint.x, viewPoint.y, 0, 0);
                }
                break;
                
            default:
                break;
        }
        NSString *windowText = NSLocalizedString(@"Cannot run task yet.\n\nWaiting for parameters to load...", @"Child window prompt : Cannot execute task.");

        [[MGSAttachedWindowController sharedController]
         showForWindow:window
         atCentreOfRect:viewRect
         withText:windowText];
        
        return NO;
    }
    
	// validate the parameters
	MGSParameterViewController *viewController;
	if (![_parameterViewManager validateParameters:&viewController]) {
		
		// highlight the invalid parameter
		[_parameterViewManager selectParameter:viewController];
		
		// scroll view visible
		[[viewController view] scrollRectToVisible:[[viewController view] bounds]];
		
		NSString *alertTitle = [NSString stringWithFormat: NSLocalizedString(@"Input %i requires a value.", "Invalid parameter value alert title"), [viewController displayIndex]];
		NSString *alertMessage = [NSString stringWithFormat: @"%@", [viewController validationString]];
		
		// show alert
		NSBeginAlertSheet(NSLocalizedString(alertTitle, @"Alert sheet text"),	// sheet message
						  NSLocalizedString(@"Okay", @"Alert sheet button text"),              //  default button label
						  nil,              //  other button label
						  nil,				// NSLocalizedString(@"Exit Configuration", @"Alert sheet button text"),             //  alternate button label
						  [[self view] window],	// window sheet is attached to
						  self,                   // we’ll be our own delegate
						  NULL, // @selector(promptExitSheetDidEnd:returnCode:contextInfo:),					// did-end selector
						  NULL,                   // no need for did-dismiss selector
						  nil,                 // context info
						  alertMessage,	// additional text
						  nil);
		return NO;
	}

	return YES;
}

#pragma mark -
#pragma mark Operation
/*
 
 execute script
 
 */
- (IBAction)executeScript:(id)sender
{

	// cannot send up the responder chain as that passes messages from view to view not from
	// controller to controller. hence use delegate.
	if (_delegate && [_delegate respondsToSelector:@selector(executeScript:)]) {
				
		[_delegate performSelector:@selector(executeScript:) withObject:sender];
	}
}

#pragma mark -
#pragma mark Window handling
/*
 
 detach action into another window
 
 */
- (IBAction)detachActionAsWindow:(id)sender
{
	#pragma unused(sender)
	
	// open this action in another window
	[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteOpenTaskInWindow object:[_action mutableDeepCopyAsNewInstance]];
	
	// close the tab containing this view
	if (0) {
		if (_delegate && [_delegate respondsToSelector:@selector(closeRequestTab)]) {
			[_delegate closeRequestTab];
		}
	}
}

/*
 
 can detach action as window
 
 */
- (BOOL)canDetachActionAsWindow
{
	if (![detachButton isHidden] && [detachButton isEnabled]) {
		return YES;
	}
	
	return NO;
}

#pragma mark -
#pragma mark Splitview handling
/*
 
 addtional dragging rect for splitview
 
 */
- (NSRect)splitViewRect
{
	return [_splitDragView frame];
}

#pragma mark -
#pragma mark Resource management
/*
 
 - dispose
 
 */
- (void)dispose
{
    _actionController = nil;
    _action = nil;
}

@end

#pragma mark -
@implementation MGSInputRequestViewController (Private)
/*
 
 index of currently selected action
 
 */
- (NSInteger)selectedActionIndex
{
	return [_actionController selectionIndex];
}

/*
 
 set index of currently selected action
 
 */
- (void)setSelectedActionIndex:(NSUInteger)idx
{
	if (idx == NSNotFound) {
			[_actionController setSelectionIndex:NSNotFound];	// a nil selection, the default nullplaceholder binding will be selected
	} else {
		if (idx < [[_actionController arrangedObjects] count]) {
			[_actionController setSelectionIndex:idx];
		} else {
			MLog(RELEASELOG, @"invalid action index requested");
		}
	}
	
	[self updateIndexMatchesPartnerIndex];
}

/*
 
 update index matches partner index
 
 */
- (void)updateIndexMatchesPartnerIndex
{
	self.indexMatchesPartnerIndex = [self selectedActionIndex] == self.selectedPartnerIndex ? YES : NO;
}
/*
 
 mark as ready if no results
 
 */
- (void)markAsReadyIfNoResults
{
	if (!_action.result) {
		[_actionController setSelectedObjects:nil];		// setting nil here will display bound null placeholder
		[_actionViewController setHighlighted:NO];
	} else {
		[_actionViewController setHighlighted:YES];
	}
}

@end
