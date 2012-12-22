//
//  MGSParameterViewHandler.m
//  Mother
//
//  Created by Jonathan on 06/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
//  The handler coordinates the creation and display of
//  the MGSParameterViews needed to display the parameters
//
// This class could really be called MGSParameterSplitViewController
//
#import "MGSParameterViewManager.h"
#import "MGSRoundedView.h"
#import "MGSScriptParameterManager.h"
#import "MGSScriptParameter.h"
#import "NSView_Mugginsoft.h"
#import "NSSplitView_Mugginsoft.h"
#import "MGSParameterSplitView.h"
#import "MGSParameterEndViewController.h"
#import "MGSParameterView.h"
#import "MGSScript.h"
#import "MGSTaskSpecifier.h"
#import "MGSNotifications.h"
#import "MGSMotherWindowController.h"
#import "MGSViewDraggingProtocol.h"

// clas extension
@interface MGSParameterViewManager ()
- (void)moveParameterAtIndex:(NSUInteger)sourceIndex toIndex:(NSUInteger)targetIndex;
- (void)inputParameterInsertMenuAction:(id)sender;
- (void)inputParameterAppendMenuAction:(id)sender;
- (MGSParameterViewController *)insertParameterAtIndex:(NSUInteger)idx;

@property BOOL parameterScrollingEnabled;
@end

@interface MGSParameterViewManager(Private)
- (MGSParameterViewController *)createView;
- (void)destroyViews;
- (void)createViews;
- (void)showViewAtIndex:(NSUInteger)index;
- (void)addSplitViewSubview:(NSView *)view;
- (void)removeSplitViewSubview:(NSView *)view;
- (void)addSplitViewParameterSubview:(NSView *)view atIndex:(NSUInteger)idx;
- (void)updateViewLocations;
- (MGSParameterViewController *)createViewForParameterAtIndex:(NSUInteger)index;
- (void)addEndViewToSplitView;
- (void)replaceSplitViewSubview:(NSView *)subView with:(NSView *)newView;
- (void)addSplitViewSubview:(NSView *)view positioned:(NSWindowOrderingMode)place relativeTo:(NSView *)otherView;
@end

@implementation MGSParameterViewManager

@synthesize mode = _mode;
@synthesize delegate = _delegate;
@synthesize actionViewController = _actionViewController;
@synthesize selectedParameterViewController = _selectedParameterViewController;
@synthesize parameterScrollingEnabled = _parameterScrollingEnabled;

/*
 
 init
 
 */
- (id)init
{
	if ((self = [super init])) {
		_viewControllers = [NSMutableArray arrayWithCapacity:1];
		self.mode = MGSParameterModeInput;
        _parameterScrollingEnabled = YES;
	}
	return self;
}

/*
 
 set action view controller 
 
 */
- (void)setActionViewController:(MGSActionViewController *)controller
{
	_actionViewController = controller;
	_actionViewController.delegate = self;
	
	MGSScript *script = [_actionViewController.action script];
	[self setScriptParameterManager: [script parameterHandler]];
	
	// put action view at top of splitview
	[self replaceSplitViewSubview:[[splitView subviews] objectAtIndex:0]  with:[_actionViewController view]];
}

/*
 
 awake from nib
 
 */
- (void) awakeFromNib
{
	// nib's owner also gets called.
	// only want this to be processed once
	if (_nibLoaded) {
		return;
	}
	_nibLoaded = YES;
	
	// this view will be replaced by parameter view
	NSAssert(([[splitView subviews] count] == 2), @"splitview subviews count should be 2");
	_splitSubView2 = [[splitView subviews] objectAtIndex:1];
    
    // add parameter type submenu for insert type menu
    NSMenuItem *menuItem = [inputParameterMenu itemWithTag:kMGSParameterInputMenuInsertType];
    NSDictionary *menuDict = [MGSParameterViewController parameterTypeMenuDictionaryWithTarget:self action:@selector(inputParameterInsertMenuAction:)];
    NSMenu *parameterMenu = [menuDict objectForKey:@"menu"];    
    [menuItem setSubmenu:parameterMenu];
    
    // add parameter type submenu for append type menu
    menuItem = [inputParameterMenu itemWithTag:kMGSParameterInputMenuAppendType];
    menuDict = [MGSParameterViewController parameterTypeMenuDictionaryWithTarget:self action:@selector(inputParameterAppendMenuAction:)];
    parameterMenu = [menuDict objectForKey:@"menu"];  
    [menuItem setSubmenu:parameterMenu];
}

/*
 
 commit all pending edits
 
 */
- (BOOL)commitPendingEdits
{
	for (MGSParameterViewController *controller in _viewControllers) {
		if (![controller commitEditing]) {
			return NO;
		}
	}
	return YES;
}

/*
 
 validate the parameters
 
 */
- (BOOL)validateParameters:(MGSParameterViewController **)parameterViewController
{
	NSInteger idx = 0;
	for (MGSParameterViewController *controller in _viewControllers) {
		if (![controller isValid]) {
			*parameterViewController = controller;
			return NO;
		}
		idx++;
	}
	
	return YES;
}

#pragma mark -
#pragma mark Accessors


/*
 
 - setSelectedParameterViewController:
 
 */
- (void)setSelectedParameterViewController:(MGSParameterViewController *)viewController
{
    [self setHighlightForAllViews:NO];
    _selectedParameterViewController = viewController;
    
    if (_selectedParameterViewController) {
        _selectedParameterViewController.isHighlighted = YES;
    }
}

/*
 
 set script parameter handler
 
 */
-(void)setScriptParameterManager:(MGSScriptParameterManager *)aScriptParameterManager
{
	NSAssert(aScriptParameterManager, @"script parameter manager is null");
	_scriptParameterManager = aScriptParameterManager;
	
	// destroy current parameter views
	[self destroyViews];
	
	// create new views for parameters
	[self createViews];
}

#pragma mark -
#pragma mark MGSParameterViewController delegate methods

/*
 
 - dragParameterView:event:
 
 */
- (void)dragParameterView:(MGSParameterViewController *)controller event:(NSEvent *)event
{
    NSUInteger viewIndex = [_viewControllers indexOfObject:controller];
    if (viewIndex == NSNotFound) {
        return;
    }
    
    NSSize dragOffset = NSMakeSize(0.0, 0.0);
    NSPoint imageLocation = NSMakePoint(0.0, 0.0);
    
    // define pasteboard
    NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
    [pboard declareTypes:@[MGSParameterViewPBoardType] owner:self];
    [pboard setPropertyList:@{ @"index" : @(viewIndex)} forType:MGSParameterViewPBoardType];

    NSImage *dragImage = controller.view.mgs_dragImage;
    [controller.view dragImage:dragImage
                            at:imageLocation
                        offset:dragOffset
                         event:event
                    pasteboard:pboard
                        source:self
                     slideBack:YES];
 
}


/*
 
 - closeParameterView
 
 */
- (void)closeParameterView:(MGSParameterViewController *)viewController
{	
	NSInteger idx = -1;
	
	if (!viewController) return;
	
	// get index of controller to remove
	for (NSUInteger i = 0; i < [_viewControllers count]; i++) {
		if ([[_viewControllers objectAtIndex:i] isEqual:viewController]) {
			idx = (NSInteger)i;
			break;
		}
	}
	if (-1 == idx) return;
	
    self.selectedParameterViewController = nil;
    
	// remove the script parameter and view controller
	[_scriptParameterManager removeItemAtIndex:idx];
	[_viewControllers  removeObject:viewController];
	
	// remove the subview
	[self removeSplitViewSubview:[viewController view]];
	
	// update view banners
	[self updateViewLocations];
	
	// inform delegate that view closed
	if (_delegate && [_delegate respondsToSelector:@selector(parameterViewDidClose:)]) {
		[_delegate parameterViewDidClose:viewController];
	}
}

/*
 
 reset enabled changed
 
 */
- (void)parameterViewController:(MGSParameterViewController *)sender didChangeResetEnabled:(BOOL)resetEnabled
{
#pragma unused(sender)
#pragma unused(resetEnabled)
	
	BOOL enabled = NO;
	for (MGSParameterViewController *viewController in _viewControllers) {
		if (viewController.resetEnabled) {
			enabled = YES;
			break;
		}
	}
	[_actionViewController setResetEnabled:enabled];
}


/*
 
 - parameterViewController:changeIndex:
 
 */
- (void)parameterViewController:(MGSParameterViewController *)viewController changeIndex:(MGSParameterIndexChange)changeIndex
{
    NSUInteger targetControllerIndex = 0;
    NSUInteger sourceControllerIndex = [_viewControllers indexOfObject:viewController];
    if (sourceControllerIndex == NSNotFound) {
        MLogDebug(@"view controller not found");
        return;
    }
    
    switch (changeIndex) {
            
        // decrease the parameter index
        case kMGSParameterIndexDecrease:
            if (sourceControllerIndex == 0) {
                return;
            }
            targetControllerIndex = sourceControllerIndex - 1;
            break;
            
        // increase the parameter index
        default:
            if (sourceControllerIndex >= [_viewControllers count] - 1) {
                return;
            }
            targetControllerIndex = sourceControllerIndex + 1;
            break;
    }
    
    [self moveParameterAtIndex:sourceControllerIndex toIndex:targetControllerIndex];
    
    [self scrollViewControllerVisible:viewController];
}

#pragma mark -
#pragma mark Parameter creation and  moving
/*
 
 - appendParameter
 
 */
- (MGSParameterViewController *)appendParameter
{
    NSUInteger idx = [_scriptParameterManager count];
    MGSParameterViewController *viewController = [self insertParameterAtIndex:idx];
	return viewController;
}

/*
 
 - insertParameterAtIndex:
 
 */
- (MGSParameterViewController *)insertParameterAtIndex:(NSUInteger)idx
{
    // create script parameter and add to handler array
	MGSScriptParameter *parameter = [MGSScriptParameter new];
	[_scriptParameterManager insertItem:parameter atIndex:idx];
	
	// create new view for parameter
	MGSParameterViewController *viewController = [self createViewForParameterAtIndex:idx];
    
	// set parameter description if set
	if ([viewController parameterDescription]) {
		[[viewController scriptParameter] setDescription:[viewController parameterDescription]];
	}
	
	// update the view locations
	[self updateViewLocations];
	
    // inform delegate that view added
	if (_delegate && [_delegate respondsToSelector:@selector(parameterViewAdded:)]) {
		[_delegate parameterViewAdded:viewController];
	}
    
	return viewController;
}

/*
 
 - moveParameterAtIndex:toIndex:
 
 */
- (void)moveParameterAtIndex:(NSUInteger)sourceIndex toIndex:(NSUInteger)targetIndex
{
    NSUInteger maxIndex = _viewControllers.count - 1;
    
    if (sourceIndex == targetIndex) return;
    if (sourceIndex > maxIndex || targetIndex > maxIndex) {
        MLogInfo(@"invalid parameter view indicies for source: %lu target: %lu", sourceIndex, targetIndex);
        return;
    }
    
    MGSParameterViewController *viewController = [_viewControllers objectAtIndex:sourceIndex];
    MGSParameterViewController *targetViewController = [_viewControllers objectAtIndex:targetIndex];
    
    // move the view controller
	[_viewControllers  removeObject:viewController];
    [_viewControllers insertObject:viewController atIndex:targetIndex];
	
    // move the script parameter
    [_scriptParameterManager moveItemAtIndex:sourceIndex toIndex:targetIndex];

    // move the splitview subview
	[self removeSplitViewSubview:[viewController view]];
    NSWindowOrderingMode position = NSWindowAbove;
    if (targetIndex < sourceIndex) {
       position = NSWindowBelow;
    }
    [self addSplitViewSubview:viewController.view positioned:position relativeTo:targetViewController.view];
    	
     // update view banners
	[self updateViewLocations];
}


#pragma mark -
#pragma mark NSDraggingSource protocol
/*
 
 - draggingSourceOperationMaskForLocal:
 
 */
- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
    NSDragOperation dragOp = NSDragOperationNone;
    
    if (isLocal) {
        dragOp = NSDragOperationEvery;
    }
    
    return dragOp;
}

#pragma mark -
#pragma mark MGSViewDraggingProtocol protocol

/*
 
 - draggingEntered:object:
 
 */
- (NSDragOperation)draggingEntered:(id < NSDraggingInfo >)sender object:(id)object
{
    NSPasteboard *pboard = [sender draggingPasteboard];
    //NSDragOperation sourceDragMask = [sender draggingSourceOperationMask];

    MGSParameterViewController *viewController = object;
    NSAssert([_viewControllers containsObject:viewController], @"bad view controller");
    
    if ( [[pboard types] containsObject:MGSParameterViewPBoardType] ) {
        //if (sourceDragMask & NSDragOperationGeneric) {
        
        if (!viewController.isHighlighted) {
            viewController.isHighlighted = YES;
        }
        return NSDragOperationGeneric;
        //}
    }
    
    return NSDragOperationNone;
}


/*
 
 - draggingUpdated:object:
 
 */
- (NSDragOperation)draggingUpdated:(id < NSDraggingInfo >)sender object:(id)object
{
#pragma unused(sender)
#pragma unused(object)  
    return NSDragOperationGeneric;
}

/*
 
 - draggingExited:object:
 
 */
- (void)draggingExited:(id < NSDraggingInfo >)sender object:(id)object
{
 
    NSPasteboard *pboard = [sender draggingPasteboard];
    //NSDragOperation sourceDragMask = [sender draggingSourceOperationMask];
    
    MGSParameterViewController *viewController = object;
    NSAssert([_viewControllers containsObject:viewController], @"bad view controller");
    
    if ( [[pboard types] containsObject:MGSParameterViewPBoardType] ) {
        //if (sourceDragMask & NSDragOperationGeneric) {
        
        if (viewController.isHighlighted) {
            viewController.isHighlighted = NO;
        }
        //}
    }
}

/*
 
 - prepareForDragOperation:object:
 
 */
- (BOOL)prepareForDragOperation:(id < NSDraggingInfo >)sender object:(id)object
{
#pragma unused(sender)
#pragma unused(object)
    
    return YES;
}

/*
 
 - performDragOperation:object:
 
 */
- (BOOL)performDragOperation:(id < NSDraggingInfo >)sender object:(id)object
{
    MGSParameterViewController *targetViewController = object;
    NSAssert([_viewControllers containsObject:targetViewController], @"bad view controller");
    
    BOOL accept = NO;
    
    //NSDragOperation sourceDragMask = [sender draggingSourceOperationMask];
    NSPasteboard *pboard = [sender draggingPasteboard];
    
    // parameter view type
    if ( [[pboard types] containsObject:MGSParameterViewPBoardType] ) {

        // get our dictionary
        NSDictionary *info = [pboard propertyListForType:MGSParameterViewPBoardType];
        NSNumber *indexNumber = [info objectForKey:@"index"];
        
        // get index of dropped view
        if (indexNumber && [indexNumber isKindOfClass:[NSNumber class]]) {
            NSInteger sourceViewIndex = [indexNumber integerValue];
            
            if (sourceViewIndex < (NSInteger)[_viewControllers count]) {
                NSInteger targetViewIndex = [_viewControllers indexOfObject:targetViewController];
                
                [self moveParameterAtIndex:sourceViewIndex toIndex:targetViewIndex];
                
                //[self performSelector:@selector(scrollViewControllerVisible:) withObject:viewController afterDelay:0];
                
            }
        }
    }

    return accept;
}

/*
 
 - concludeDragOperation:object:
 
 */
- (void)concludeDragOperation:(id < NSDraggingInfo >)sender object:(id)object
{
#pragma unused(sender)
#pragma unused(object)    
}

/*
 
 - draggingEnded:object:
 
 */
- (void)draggingEnded:(id < NSDraggingInfo >)sender object:(id)object
{
#pragma unused(sender)
#pragma unused(object)
}

#pragma mark -
#pragma mark Methods


/*
 
 reset to default value
 
 */
- (void)resetToDefaultValue
{
	for (MGSParameterViewController *viewController in _viewControllers) {
		[viewController resetToDefaultValue]; 
	}	
}

/*
 
 controller view clicked

 this message is sent whenever a click occurs anywhere in a parameter view or
 the top action view
 
 */
- (void)controllerViewClicked:(MGSRoundedPanelViewController *)controller
{
    
    if (![self commitPendingEdits]) return;
    
	BOOL showMenu = NO;
	
    _lastCickedParmeterViewController = (MGSParameterViewController *)controller;
    
    NSUInteger viewIndex = [_viewControllers indexOfObject:controller];
    if (viewIndex == NSNotFound) {
        return;
    }
    
	NSEvent *event = [NSApp currentEvent];
	switch ([event type]) {
		case NSLeftMouseDown:					
			
			// double clicking triggering max/min tab may interefere with running task on double click 
			if ([event clickCount] == 2 && NO) {
				[NSApp sendAction:@selector(subviewDoubleClick:) to:nil from:controller];
				return;
			}
			
			if (([event modifierFlags] & NSControlKeyMask)) {
				showMenu = YES;
			}


			
			break;
				
		case NSRightMouseDown:
			showMenu = YES;
			break;
	}
	
    // select controller view
    if (controller != self.selectedParameterViewController) {
        self.selectedParameterViewController = _lastCickedParmeterViewController;
    }
    
	if (showMenu) {
        
        switch (_mode) {
            case MGSParameterModeInput:
                [[NSNotificationCenter defaultCenter] postNotificationName:MGSShowTaskTabContextMenu object:event userInfo:nil];
                break;
            
            case MGSParameterModeEdit:
            {
                // show the input parameter menu
                [NSMenu popUpContextMenu:inputParameterMenu withEvent:event forView:splitView];
            }
                break;
        }
	}
}



#pragma mark -
#pragma mark Parameter selection and highlighting

/*
 
 - selectParameter:
 
 */
- (void)selectParameter:(MGSParameterViewController *)controller
{
    self.selectedParameterViewController = controller;
}


/*
 
 - selectParameterAtIndex:
 
 */
- (void)selectParameterAtIndex:(NSUInteger)idx
{
	if (idx < [_viewControllers count]) {
		[self selectParameter:[_viewControllers objectAtIndex:idx]];
	}
}

/*
 
 set highlight for all views
 
 */
- (void)setHighlightForAllViews:(BOOL)aBool
{
	// parameter views
	for (MGSParameterViewController *viewController in _viewControllers) {
		if ([viewController isHighlighted] != aBool) {
			[viewController setIsHighlighted:aBool];
		}
	}
	
	// view
	if (_actionViewController.isHighlighted != aBool) {
		[_actionViewController setIsHighlighted:aBool];
	}
}

/*
 
 highlight the action view
 
 */
- (void)highlightActionView
{
	[self controllerViewClicked:_actionViewController];
}


#pragma mark -
#pragma mark NSMenuValidation protocol

/*
 
 - validateMenuItem:
 
 */
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    
    if (!_lastCickedParmeterViewController) {
        return NO;
    }
    
    NSUInteger viewIndex = [_viewControllers indexOfObject:_lastCickedParmeterViewController];
    if (viewIndex == NSNotFound) {
        return NO;
    }
    
    BOOL valid = YES;
    
    switch (menuItem.tag) {
        case kMGSParameterInputMenuMoveUp:
            valid = (viewIndex == 0 ? NO : YES);
            break;

        case kMGSParameterInputMenuMoveDown:
            valid = (viewIndex >= [_viewControllers count] - 1) ? NO : YES;
            break;
            
        case kMGSParameterInputMenuInsert:            
        case kMGSParameterInputMenuAppend:
        case kMGSParameterInputMenuDuplicate:
        case kMGSParameterInputMenuRemove:
        case kMGSParameterInputMenuInsertType:
        case kMGSParameterInputMenuAppendType:
            break;
    }
    
    return valid;
}

#pragma mark -
#pragma mark Views

/*
 
 - scrollViewControllerVisible:
 
 */
- (void)scrollViewControllerVisible:(MGSParameterViewController *)viewController
{
    if (self.parameterScrollingEnabled) {
        // call display before scrolling otherwise scrolling visible is unreliable
        // after modifying the splitview content
        [splitView display];
        
        // scroll the view to make visible
        [viewController.view scrollRectToVisible:viewController.view.bounds];
    }
}
#pragma mark -
#pragma mark Actions

/*
 
 - insertInputParameterAction:
 
 */
- (IBAction)insertInputParameterAction:(id)sender
{
#pragma unused(sender)
    
    if (![self commitPendingEdits]) return;

    // get location at which to insert the input
    MGSParameterViewController *targetViewController = self.selectedParameterViewController;
    if (!targetViewController) return;
    
#if 0
    // add parameter
    MGSParameterViewController *sourceViewController = [self appendParameter];

    // move to desired location
    NSUInteger sourceIndex = [_viewControllers indexOfObject:sourceViewController];
    NSUInteger targetIndex = [_viewControllers indexOfObject:targetViewController];
    
    // if sender is a script parameter then use it
    if ([sender isKindOfClass:[MGSScriptParameter class]]) {
        
        // copy the script parameter and update the manager
        MGSScriptParameter *scriptParameter = [(MGSScriptParameter *)sender mutableDeepCopy];
        [_scriptParameterManager replaceItemAtIndex:sourceIndex withItem:scriptParameter];
        
        sourceViewController.scriptParameter = scriptParameter;
    }
    
    if (sourceIndex != targetIndex && sourceIndex != NSNotFound && targetIndex != NSNotFound) {
        [self moveParameterAtIndex:sourceIndex toIndex:targetIndex];
    }
#else
    NSUInteger targetIndex = [_viewControllers indexOfObject:targetViewController];

    // insert parameter
    MGSParameterViewController *sourceViewController = [self insertParameterAtIndex:targetIndex];

    // if sender is a script parameter then use it
    if ([sender isKindOfClass:[MGSScriptParameter class]]) {
        
        // copy the script parameter and update the manager
        MGSScriptParameter *scriptParameter = [(MGSScriptParameter *)sender mutableDeepCopy];
        [_scriptParameterManager replaceItemAtIndex:targetIndex withItem:scriptParameter];
        
        sourceViewController.scriptParameter = scriptParameter;
    }

#endif
    
    // select new view
    self.selectedParameterViewController = sourceViewController;
    
    [self scrollViewControllerVisible:sourceViewController];
}

/*
 
 - appendInputParameterAction:
 
 */
- (IBAction)appendInputParameterAction:(id)sender
{
#pragma unused(sender)
    
    if (![self commitPendingEdits]) return;
    
    // create parameter
    MGSParameterViewController *parameterViewController = [self appendParameter];
    
    // select new view
    self.selectedParameterViewController = parameterViewController;
    
    [self scrollViewControllerVisible:parameterViewController];
}

/*
 
 - duplicateInputParameterAction:
 
 */
- (IBAction)duplicateInputParameterAction:(id)sender
{
#pragma unused(sender)    
    if (![self commitPendingEdits]) return;
    if (!self.selectedParameterViewController) return;

    // the parameter model only updates on request
    [self.selectedParameterViewController updateModel];
    
    // insert parameter and set scriptParameter
    [self insertInputParameterAction:self.selectedParameterViewController.scriptParameter];
}

/*
 
 - removeInputParameterAction:
 
 */
- (IBAction)removeInputParameterAction:(id)sender
{
#pragma unused(sender)
    if (![self commitPendingEdits]) return;
    
    if (self.selectedParameterViewController) {
        [self closeParameterView:self.selectedParameterViewController];
    }
}

/*
 
 - moveUpInputParameterAction:
 
 */
- (IBAction)moveUpInputParameterAction:(id)sender
{
#pragma unused(sender)

    if (![self commitPendingEdits]) return;
    
    // get view to move
    if (!self.selectedParameterViewController) return;
    
    [self parameterViewController:self.selectedParameterViewController changeIndex:kMGSParameterIndexDecrease];
}

/*
 
 - moveDownInputParameterAction:
 
 */
- (IBAction)moveDownInputParameterAction:(id)sender
{
#pragma unused(sender)
    if (![self commitPendingEdits]) return;
    
    // get view to move
    if (!self.selectedParameterViewController) return;
    
    [self parameterViewController:self.selectedParameterViewController changeIndex:kMGSParameterIndexIncrease];
}

/*
 
 - inputParameterInsertMenuAction
 
 */
- (void)inputParameterInsertMenuAction:(id)sender
{
    if (![self commitPendingEdits]) return;
    
    // get location at which to insert the input
    MGSParameterViewController *viewController = self.selectedParameterViewController;
    if (!viewController) return;
	
    // insert parameter 
    [self insertInputParameterAction:self];
    if (viewController == self.selectedParameterViewController) return;
    
	[self.selectedParameterViewController selectParmaterTypeWithMenuTag:[sender tag]];
}

/*
 
 - inputParameterAppendMenuAction
 
 */
- (void)inputParameterAppendMenuAction:(id)sender
{
    if (![self commitPendingEdits]) return;
    
    // get location at which to insert the input
    MGSParameterViewController *viewController = self.selectedParameterViewController;
    if (!viewController) return;
	
    // append parameter
    self.parameterScrollingEnabled = NO;
    [self appendInputParameterAction:self];
    if (viewController == self.selectedParameterViewController) return;
    
	[self.selectedParameterViewController selectParmaterTypeWithMenuTag:[sender tag]];
    
    self.parameterScrollingEnabled = YES;
    [self scrollViewControllerVisible:self.selectedParameterViewController];
}
@end


@implementation MGSParameterViewManager(Private)

/*
 
 creat view for parameter at index
 
 */
- (MGSParameterViewController *)createViewForParameterAtIndex:(NSUInteger)idx
{
	// create new view
	// we are loading views from a nib here so the outlets
	// will not be available until awakeFromNib returns
	MGSParameterViewController *viewController = [self createView];

	// pass script parameters to the controller
	viewController.scriptParameter = [_scriptParameterManager itemAtIndex:idx];
	[viewController setDisplayIndex:idx+1];		
	
    // insert object
	[_viewControllers insertObject:viewController atIndex:idx];
    
    // show view
    [self showViewAtIndex:idx];
    
	return viewController;
}

/*
 
 update view locations.
 
 */
- (void)updateViewLocations
{
	// loop through views
	for (NSUInteger i = 0; i < [_viewControllers count]; i++) {
		
        MGSParameterViewController *viewController = [_viewControllers objectAtIndex:i];
				
		// set view right banner
		NSString *format = NSLocalizedString(@"%i", @"Parameter right banner format string");
		viewController.bannerRight = [NSString stringWithFormat:format, i + 1];
		
		if (i != [_viewControllers count] - 1) {
			[viewController.parameterView setHasConnector:YES];
		} else {
			[viewController.parameterView setHasConnector:NO];
		}
        
        viewController.canDecreaseDisplayIndex = (i == 0 ? NO : YES);
        viewController.canIncreaseDisplayIndex = (i >= _viewControllers.count - 1 ? NO : YES);

        viewController.displayIndex = i+1;
	}
}

/*
 
 replace splitview subview
 
 new view must have its frame already set
 
 */
- (void) replaceSplitViewSubview:(NSView *)subView with:(NSView *)newView
{
	[splitView replaceSubview:subView with:newView];
	//[splitView autoSizeHeight];
}

/*
 
 add subview to splitview
 
 */
- (void)addSplitViewSubview:(NSView *)view
{
	[splitView addSubview:view];
	//[splitView autoSizeHeight];
}


/*
 
 add parameter subview to splitview
 
 */
- (void)addSplitViewParameterSubview:(NSView *)view atIndex:(NSUInteger)idx
{
	// get last splitview subview
	NSView *lastView = [[splitView subviews] lastObject];
	
	// always want our view at the end of our subview array.
	// if end view exists insert our view before it.
	if (lastView == [_endViewController view]) {
        
        NSWindowOrderingMode position = 0;
        
        if (idx <= [[splitView subviews] count] - 1) {
            position = NSWindowBelow;
        } else {
            position = NSWindowAbove;
        }

		[self addSplitViewSubview:view positioned:position relativeTo:[[splitView subviews] objectAtIndex:idx]];
	} else {
		// add additional subview
		[self addSplitViewSubview:view];
	}	
}

/*
 
 add splitview subview in view hierarchy relative to another view
 
 */
- (void)addSplitViewSubview:(NSView *)view positioned:(NSWindowOrderingMode)place relativeTo:(NSView *)otherView
{
	[splitView addSubview:view positioned:place relativeTo:otherView];
	//[splitView autoSizeHeight];	
}

/* 
 
 add end view to split view
 
 our splitview must always have a specific end view
 
 */
- (void)addEndViewToSplitView
{
	NSInteger parameterCount = [_scriptParameterManager count];
	
	if (parameterCount > 0) {
		
		// lazy controller creation
		if (!_endViewController) {
			_endViewController = [[MGSParameterEndViewController alloc] init];
		}

		// if our last view is not the end view then add one
		NSView *lastView = [[splitView subviews] lastObject];
		if (lastView != [_endViewController view]) {
			[self addSplitViewSubview:[_endViewController view]];
		}		
	}
	
}
/*
 
 remove subview from splitview
 
 */
- (void)removeSplitViewSubview:(NSView *)view
{
	// maintain two views in splitview
	if (2 == [[splitView subviews] count]) {
		NSView *emptyView = [[NSView alloc] initWithFrame:[view frame]];
		[self replaceSplitViewSubview:view  with:emptyView];
	} else {
		[view removeFromSuperview];
	}
}
/*
 
 create new parameter sub view and add to the splitview
 
 */
- (MGSParameterViewController *)createView
{
	// create new view
	MGSParameterViewController *viewController = [[MGSParameterViewController alloc] initWithMode:self.mode];
	[viewController setDelegate:self];
	
	// load the view now.
	// sending the view message will trigger view loading.
	// -awakeFromNib will be called before this message returns.
	// lazy loading can lead to lots of problems if it is not anticipated.
	[viewController view];
	
    [[viewController view] registerForDraggedTypes:@[MGSParameterViewPBoardType]];
    
	// our view controller now references a fully initialised object
	return viewController;
}

/*
 
 show view at index.
 
 */
- (void) showViewAtIndex:(NSUInteger)idx
{
	MGSParameterViewController *viewController = [_viewControllers objectAtIndex:idx];
	NSView *view = [viewController view];
	
	// determine if first sub view contains action view
	BOOL firstSubviewIsAction = _actionViewController ? YES : NO;
	
	// replace second subview.
	// want to keep at least two subviews in out splitview.
	if ([_viewControllers count] == 1) {
		NSAssert(([[splitView subviews] count] == 2), @"splitview subviews count should be 2");
		NSAssert(_splitSubView2, @"splitview sub view 2 is nil");
		
		// if no action view then make top splitview
		// narrow to provide margin for first parameter view below it
		if (!firstSubviewIsAction) {
			NSView *firstView = [[splitView subviews] objectAtIndex:0];
			NSSize firstViewSize = [firstView frame].size;
			firstViewSize.height = 6;
			[firstView setFrameSize:firstViewSize];
		}
		
		// first view always allocated.
		// either contains action view or is empty to provide top margin for parameter list
		idx = 1;
		
		// replace existing view with new view
		[self replaceSplitViewSubview:[[splitView subviews] objectAtIndex:idx]  with:view];
	} else {
		[self addSplitViewParameterSubview:view atIndex:idx];
	}
	
	// make sure that our splitview subviews are terminated
	[self addEndViewToSplitView];
}

/*
 
 create views
 
 create a view for each script parameter.
 
 this message is sent for all modes.
 
 */
- (void)createViews
{
	int i;
	
	NSAssert([_viewControllers count] == 0, @"view controllers array not empty");
	
	// show a view for each parameter
	for (i = 0; i < [_scriptParameterManager count]; i++) {
		[self createViewForParameterAtIndex:i];
	}
	
	// update views with new locations
	[self updateViewLocations];
}

/*
 
 destroy views
 
 */
- (void)destroyViews
{
	MGSParameterViewController *viewController;
	
	// remove the end view
	if ([_endViewController view]) {
		[[_endViewController view] removeFromSuperviewWithoutNeedingDisplay];
	}
	
	// remove the existing views from the splitview
	for (NSInteger i = [_viewControllers count]-1; i >= 0 ; i--) {
		viewController = [_viewControllers objectAtIndex:i];
		viewController.scriptParameter = nil;	// no longer references a parameter
		NSView *view = [viewController view];
		
		// need to keep a minimum of 2 subviews in the splitview
		if (i == 0) {
			NSAssert(([[splitView subviews] count] == 2), @"splitview subviews count should be 2");
			[splitView replaceSubview:view withViewSizedAsOld: _splitSubView2];
		} else {
			[view removeFromSuperviewWithoutNeedingDisplay];
		}
		
		// remove controller
		[_viewControllers removeObjectAtIndex:i];
	}
	NSAssert([_viewControllers count] == 0, @"view controllers array not empty");
}

/*
 
 hide views
 
 */
/*
- (void)hideViews
{
	MGSParameterViewController *viewController;
	int i;
	
	if ([_endViewController view]) {
		[[_endViewController view] removeFromSuperviewWithoutNeedingDisplay];
	}
	
	// remove the existing views from the splitview
	for (i = [_viewControllers count]-1; i >= 0 ; i--) {
		viewController = [_viewControllers objectAtIndex:i];
		viewController.scriptParameter = nil;	// no longer references a parameter
		NSView *view = [viewController view];
		
		// need to keep a minimum of 2 subviews in the splitview
		if (i == 0) {
			NSAssert(([[splitView subviews] count] == 2), @"splitview subviews count should be 2");
			[splitView replaceSubview:view withViewSizedAsOld: _splitSubView2];
		} else {
			[view removeFromSuperviewWithoutNeedingDisplay];
		}
		
		// add view to cache
		[_viewControllers removeObjectAtIndex:i];
		[_viewControllerCache addObject: viewController];
	}
	NSAssert([_viewControllers count] == 0, @"view controllers array not empty");
}
*/
/*
 
 show views
 
 */
/*
- (void)showViews
{
	MGSParameterViewController *viewController;
	int i;
	
	NSAssert([_viewControllers count] == 0, @"view controllers array not empty");
	
	// show a view for each parameter
	for (i = 0; i < [_scriptParameterHandler count]; i++) {
		
		// use cached view if available		
		if ([_viewControllerCache count] > 0) {
			viewController = [_viewControllerCache objectAtIndex:0];
			[_viewControllerCache removeObjectAtIndex:0];			
		} else {
			// create new view
			// we are loading views from a nib here so the outlets
			// will not be available until awakeFromNib returns
			viewController = [self createView];
		}
		
		// pass script parameters to the controller
		viewController.scriptParameter = [_scriptParameterHandler itemAtIndex:i];
		[viewController setDisplayIndex:i+1];		
		
		// show view
		[_viewControllers insertObject:viewController atIndex:i];	
		[self showViewAtIndex: i];
	}
	
	// to enable resizing of last parameter need to add
	// a dummy view to end of splitview
	if (i > 0) {
		if (!_endViewController) {
			_endViewController = [[MGSParameterEndViewController alloc] init];
		}
		[self addSplitViewSubview:[_endViewController view]];
	}
	
	[splitView setNeedsDisplay:YES];
	
	[self updateViewBanners];
}
*/



@end

#pragma mark NSSplitView delegate messages
@implementation MGSParameterViewManager(SplitViewDelegate)

/*
 
 get additional rect to be used to drag splitview
 
 */
- (NSRect)splitView:(NSSplitView *)aSplitView additionalEffectiveRectOfDividerAtIndex:(NSInteger)dividerIndex
{	
	#pragma unused(aSplitView)
	#pragma unused(dividerIndex)

	
	// the NSSPlitView subclass handles all of this
	return NSZeroRect;
}

/*
 
 splitview has changed size
 
 */
- (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize:(NSSize)oldSize
{
	#pragma unused(oldSize)
	
	// layout out subviews
	if ([sender isKindOfClass:[MGSParameterSplitView class]]) {
		[(MGSParameterSplitView *)sender adjustSubviews];
	} else {
		[sender adjustSubviews];
	}
}
@end
