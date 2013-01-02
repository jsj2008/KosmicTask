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
#import "MGSParameterPluginController.h"
#import "MGSParameterPlugin.h"
#import "MGSAppCOntroller.h"

#undef MGS_DEBUG_PARAMETER_DRAG

NSTimer * m_draggingAutoscrollTimer = nil;

NSString * MGSInputParameterException = @"MGSInputParameterException";
NSString * MGSInputParameterUndoException = @"MGSInputParameterUndoException";
NSString * MGSInputParameterDragException = @"MGSInputParameterDragException";

// class extension
@interface MGSParameterViewManager ()
- (void)moveParameterAtIndex:(NSUInteger)sourceIndex toIndex:(NSUInteger)targetIndex;
- (void)inputParameterInsertMenuAction:(id)sender;
- (void)inputParameterAppendMenuAction:(id)sender;
- (MGSParameterViewController *)insertScriptParameter:(MGSScriptParameter *)parameter AtIndex:(NSUInteger)idx;
- (NSPasteboard *)cutAndPastePasteBoard;
- (IBAction)pasteInputParameterAction:(id)sender;
- (MGSScriptParameter *)pasteBoardScriptParameter;
- (void)undoInputParameterChange:(NSDictionary *)undoDict;
- (void)registerUndoForObject:(NSDictionary *)object;
- (void)timerAutoscrollCallback:(NSTimer *)timer;
- (void)undoNotification:(NSNotification *)note;

@property BOOL parameterScrollingEnabled;
@property (copy) NSString *undoActionName;
@property (copy) NSString *undoActionOperation;

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
@synthesize undoActionName = _undoActionName;
@synthesize undoActionOperation = _undoActionOperation;
@synthesize canUndo = _canUndo;

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
    
    
    // add parameter type submenu for minimial add type menu
    menuItem = [minimalInputParameterMenu itemWithTag:kMGSParameterInputMenuAppendType];
    menuDict = [MGSParameterViewController parameterTypeMenuDictionaryWithTarget:self action:@selector(inputParameterAppendMenuAction:)];
    parameterMenu = [menuDict objectForKey:@"menu"];
    [menuItem setSubmenu:parameterMenu];
    
    parameterInputUndoManager = [[NSUndoManager alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(undoNotification:) name:NSUndoManagerDidUndoChangeNotification object:parameterInputUndoManager];
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
#pragma mark Notification handling

/*
 
 - undoNotification:
 
 */
- (void)undoNotification:(NSNotification *)note
{
#pragma unused(note)
    
    if ([note.name isEqualToString:NSUndoManagerDidUndoChangeNotification] ) {
        self.canUndo = [parameterInputUndoManager canUndo];
    }
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
        
        if (self.parameterScrollingEnabled) {
            [self scrollViewControllerVisible:_selectedParameterViewController];
        }
    }
}

/*
 
 set script parameter handler
 
 */
-(void)setScriptParameterManager:(MGSScriptParameterManager *)aScriptParameterManager
{
    [parameterInputUndoManager removeAllActions];
    [parameterInputUndoManager disableUndoRegistration];
    
	NSAssert(aScriptParameterManager, @"script parameter manager is null");
	_scriptParameterManager = aScriptParameterManager;
	
	// destroy current parameter views
	[self destroyViews];
	
	// create new views for parameters
	[self createViews];
    
    [parameterInputUndoManager enableUndoRegistration];
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
    
    NSPoint event_location = [event locationInWindow];
    NSPoint local_point = [controller.view convertPoint:event_location fromView:nil];
    NSPoint imageLocation = NSMakePoint(0.0, 0.0);
    
    // define pasteboard
    NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
    [pboard declareTypes:@[MGSParameterViewPBoardType] owner:self];
    
    [controller updateModel];
    MGSScriptParameter *scriptParameter = controller.scriptParameter.mutableCopy;
    [pboard setPropertyList:@{ @"scriptParameterDict" : scriptParameter.dict, @"index" : @(viewIndex) } forType:MGSParameterViewPBoardType];

    NSImage *dragImage = controller.view.mgs_dragImage;
    NSSize newImageSize = dragImage.size;
    NSSize viewSize = controller.view.frame.size;
    
    CGFloat newWidth = 300.0f;
    
    if (dragImage.size.width > newWidth) {
        CGFloat newHeight = newWidth * dragImage.size.height / dragImage.size.width;
        newImageSize = NSMakeSize(newWidth, newHeight);
        [dragImage setSize:newImageSize];
        
        imageLocation = NSMakePoint(local_point.x - newImageSize.width * local_point.x/viewSize.width, local_point.y - newImageSize.height);
    }
    
    [controller.view dragImage:dragImage
                            at:imageLocation
                        offset:NSMakeSize(0.0, 0.0) // unused
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
	NSUInteger idx = NSNotFound;
	NSUInteger changedIndex = NSNotFound;
    
	if (!viewController) return;
	
    // need the model to be up to date if we restore the view via undo
    [viewController updateModel];
    
	// get index of controller to remove
	for (NSUInteger i = 0; i < [_viewControllers count]; i++) {
		if ([[_viewControllers objectAtIndex:i] isEqual:viewController]) {
			idx = (NSInteger)i;
			break;
		}
	}
	if (NSNotFound == idx) return;
	changedIndex = idx;
    
    self.selectedParameterViewController = nil;
    
	// remove the script parameter and view controller
	[_scriptParameterManager removeItemAtIndex:idx];
	[_viewControllers  removeObject:viewController];
	
	// remove the subview
	[self removeSplitViewSubview:[viewController view]];
	
	// update view banners
	[self updateViewLocations];
	
    if ([_viewControllers count] > 0) {
        if (idx >= [_viewControllers count] - 1) {
            idx = [_viewControllers count] - 1;
        }
        self.selectedParameterViewController = [_viewControllers objectAtIndex:idx];
    }

	// inform delegate that view closed
	if (_delegate && [_delegate respondsToSelector:@selector(parameterViewDidClose:)]) {
		[_delegate parameterViewDidClose:viewController];
	}
    
    
    // register undo
    NSDictionary *undoObject = @{ @"scriptParameter" : viewController.scriptParameter.mutableDeepCopy, @"changedIndex" : @(changedIndex) };
    self.undoActionName = NSLocalizedString(@"Close Input", @"Parameter close undo");
    self.undoActionOperation = @"close";
    [self registerUndoForObject:undoObject];
}

/*
 
 - parameterViewControllerTypeWillChange:
 
 */
- (void)parameterViewControllerTypeWillChange:(MGSParameterViewController *)viewController
{
    if ([parameterInputUndoManager isUndoRegistrationEnabled]) {
        
        [viewController updateModel];
        MGSScriptParameter *scriptParameter = viewController.scriptParameter.mutableDeepCopy;

        NSUInteger changedIndex = [_viewControllers indexOfObject:viewController];

        // register undo
        self.undoActionName = NSLocalizedString(@"Change Input Type", @"Parameter change type undo");
        self.undoActionOperation =  @"type";
        NSDictionary *undoObject = @{ @"changedIndex" : @(changedIndex), @"scriptParameter" : viewController.scriptParameter.mutableDeepCopy, @"scriptParameter" : scriptParameter};
        [self registerUndoForObject:undoObject];
    }
}

/*
 
 - parameterViewControllerTypeDidChange:
 
 */
- (void)parameterViewControllerTypeDidChange:(MGSParameterViewController *)viewController
{
#pragma unused(viewController)
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
            self.undoActionName = NSLocalizedString(@"Move Input Up", @"Parameter move up undo");
            if (sourceControllerIndex == 0) {
                return;
            }
            targetControllerIndex = sourceControllerIndex - 1;
            break;
            
        // increase the parameter index
        default:
            self.undoActionName = NSLocalizedString(@"Move Input Down", @"Parameter move down undo");
            if (sourceControllerIndex >= [_viewControllers count] - 1) {
                return;
            }
            targetControllerIndex = sourceControllerIndex + 1;
            break;
    }

    [self moveParameterAtIndex:sourceControllerIndex toIndex:targetControllerIndex];
    self.selectedParameterViewController = viewController;

    
    // register undo
    self.undoActionOperation =  @"move";
    NSDictionary *undoObject = @{ @"scriptParameter" : self.selectedParameterViewController.scriptParameter.mutableDeepCopy, @"changedIndex" : @(targetControllerIndex), @"originalIndex" : @(sourceControllerIndex)};
    [self registerUndoForObject:undoObject];
}

#pragma mark -
#pragma mark Parameter creation and  moving
/*
 
 - appendParameter
 
 */
- (MGSParameterViewController *)appendParameter
{
    NSUInteger idx = [_scriptParameterManager count];
    MGSParameterViewController *viewController = [self insertScriptParameter:nil AtIndex:idx];
	return viewController;
}

/*
 
 - insertScriptParameter:AtIndex:
 
 */
- (MGSParameterViewController *)insertScriptParameter:(MGSScriptParameter *)parameter AtIndex:(NSUInteger)idx
{
    // create script parameter and add to handler array
    if (!parameter) {
        parameter = [MGSScriptParameter new];
    }
    
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

/*
 
 - draggedImage:movedTo:
 
 */
- (void)draggedImage:(NSImage *)anImage movedTo:(NSPoint)screenPoint
{
#pragma unused(anImage)
#pragma unused(screenPoint)
    
}

/*
 
 - draggedImage:beganAt:
 
 */
- (void)draggedImage:(NSImage *)anImage beganAt:(NSPoint)aPoint
{
    #pragma unused(anImage)
    #pragma unused(aPoint)

}

/*
 
 - draggedImage:endedAt:operation:
 
 
 */
- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation
{
    #pragma unused(anImage)
    #pragma unused(aPoint)
    #pragma unused(operation)
    
    [m_draggingAutoscrollTimer invalidate];
    m_draggingAutoscrollTimer = nil;

#ifdef MGS_DEBUG_PARAMETER_DRAG
    NSLog(@"Drag ended. Timer invalidated.");
#endif
}

#pragma mark -
#pragma mark Drag and drop support

/*
 
 - timerAutoscrollCallback
 
 */
- (void)timerAutoscrollCallback:(NSTimer *)timer
{

    MGSParameterViewController *viewController = timer.userInfo;
    if (![viewController isKindOfClass:[MGSParameterViewController class]]) {
        return;
    }
    NSView *draggedView = viewController.view;
    
    NSEvent *event = [NSApp currentEvent];
    if ([event type] == NSLeftMouseDragged) {
        [draggedView autoscroll:event];
        
#ifdef MGS_DEBUG_PARAMETER_DRAG
        NSLog(@"Timer expired: Auto scrolling parameter view");
#endif
       }
}

#pragma mark -
#pragma mark MGSViewDraggingProtocol protocol

/*
 
 - draggingEntered:object:
 
 these methods are received from the viewController which may be able
 to deal with them directly rather than handling them here.
 
 */
- (NSDragOperation)draggingEntered:(id < NSDraggingInfo >)sender object:(id)object
{
    
    NSUInteger dragOperation = NSDragOperationNone;
    NSPasteboard *pboard = [sender draggingPasteboard];
    //NSDragOperation sourceDragMask = [sender draggingSourceOperationMask];
    
    if ([m_draggingAutoscrollTimer isValid]) {
        [m_draggingAutoscrollTimer invalidate];
        m_draggingAutoscrollTimer = nil;
        
#ifdef MGS_DEBUG_PARAMETER_DRAG
        NSLog(@"Drag entered. Timer invalidated.");
#endif
        
    }
        
    if ( [[pboard types] containsObject:MGSParameterViewPBoardType] ) {

        if ([object isKindOfClass:[MGSParameterViewController class]]) {
                
            MGSParameterViewController *viewController = object;
            NSAssert([_viewControllers containsObject:viewController], @"bad view controller");

            //if (sourceDragMask & NSDragOperationGeneric) {
            
            if (!viewController.dragging && viewController.mode == MGSParameterModeEdit) {
                viewController.isDragTarget = YES;
                dragOperation = NSDragOperationGeneric;
            }
            
            m_draggingAutoscrollTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                                        target:self
                                                                      selector:@selector(timerAutoscrollCallback:)
                                                                      userInfo:object
                                                                       repeats:YES];
#ifdef MGS_DEBUG_PARAMETER_DRAG
            NSLog(@"Parameter scroll callback timer activated.");
#endif
                //}

        } else if ([object isKindOfClass:[MGSParameterEndViewController class]]) {
             MGSParameterEndViewController *endViewController = object;
            
            endViewController.isDragTarget = YES;
            dragOperation = NSDragOperationGeneric;
        }
    }
    
    return dragOperation;
}


/*
 
 - draggingUpdated:object:
 
 */
- (NSDragOperation)draggingUpdated:(id < NSDraggingInfo >)sender object:(id)object
{
#pragma unused(sender)
#pragma unused(object)  
    if ([object isKindOfClass:[MGSParameterViewController class]]) {
    }
    
    return NSDragOperationGeneric;
}

/*
 
 - draggingExited:object:
 
 */
- (void)draggingExited:(id < NSDraggingInfo >)sender object:(id)object
{
    NSPasteboard *pboard = [sender draggingPasteboard];

    if ( [[pboard types] containsObject:MGSParameterViewPBoardType] ) {

        if ([object isKindOfClass:[MGSParameterViewController class]]) {
            //NSDragOperation sourceDragMask = [sender draggingSourceOperationMask];
            
            MGSParameterViewController *viewController = object;
            NSAssert([_viewControllers containsObject:viewController], @"bad view controller");
            
                //if (sourceDragMask & NSDragOperationGeneric) {
                
            if (!viewController.dragging) {
                viewController.isDragTarget = NO;
            }
                //}
        } else if ([object isKindOfClass:[MGSParameterEndViewController class]]) {
            MGSParameterEndViewController *endViewController = object;
            
            endViewController.isDragTarget = NO;
        }
    } 
}

/*
 
 - prepareForDragOperation:object:
 
 */
- (BOOL)prepareForDragOperation:(id < NSDraggingInfo >)sender object:(id)object
{
#pragma unused(sender)
#pragma unused(object)

    BOOL accept = NO;
    if ([object isKindOfClass:[MGSParameterViewController class]]) {
            
        MGSParameterViewController *targetViewController = object;
        if ([_viewControllers containsObject:targetViewController]) {
            
            if (!targetViewController.dragging && targetViewController.mode == MGSParameterModeEdit) {
                accept = YES;
            }
        }
    } else if ([object isKindOfClass:[MGSParameterEndViewController class]]) {
        accept = YES;
    }
    
    return accept;
}

/*
 
 - performDragOperation:object:
 
 */
- (BOOL)performDragOperation:(id < NSDraggingInfo >)sender object:(id)object
{
    BOOL accept = NO;

    if (![self commitPendingEdits]) return accept;
    
    //NSDragOperation sourceDragMask = [sender draggingSourceOperationMask];
    NSPasteboard *pboard = [sender draggingPasteboard];

    // parameter view type
    if ( [[pboard types] containsObject:MGSParameterViewPBoardType] ) {

        BOOL appendInput = NO;
        
        @try {

            if ([object isKindOfClass:[MGSParameterViewController class]]) {
            
                MGSParameterViewController *targetViewController = object;
                NSAssert([_viewControllers containsObject:targetViewController], @"bad view controller");

                self.selectedParameterViewController = targetViewController;
                
                accept = YES;
                
            } else if ([object isKindOfClass:[MGSParameterEndViewController class]]) {
                
                accept = YES;
                appendInput = YES;
            }

            if (accept) {
                // get our dictionary
                NSDictionary *info = [pboard propertyListForType:MGSParameterViewPBoardType];
                NSDictionary *scriptParameterDict = [info objectForKey:@"scriptParameterDict"];
                
                if (!scriptParameterDict || ![scriptParameterDict isKindOfClass:[NSDictionary class]]) {
                    [NSException raise:MGSInputParameterDragException format:@"Script parameter dictionary not found"];
                }
                
                MGSScriptParameter *scriptParameter = [[MGSScriptParameter alloc] initWithDictionary:scriptParameterDict];
                
                // configure undo
                self.undoActionName = NSLocalizedString(@"Paste Input", @"Parameter paste undo");
                self.undoActionOperation = @"paste";
                
                if ([_viewControllers count] == 0 || appendInput) {
                    [self appendInputParameterAction:scriptParameter];
                } else if ([self canPasteInputParameter]) {
                    [self insertInputParameterAction:scriptParameter];
                }
            }

        } @catch (NSException *e) {
            MLogInfo(@"%@ : %@", e.name, e.reason);
            accept = NO;
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
    if ([object isKindOfClass:[MGSParameterViewController class]]) {
    }
}

/*
 
 - draggingEnded:object:
 
 */
- (void)draggingEnded:(id < NSDraggingInfo >)sender object:(id)object
{
    NSPasteboard *pboard = [sender draggingPasteboard];
    //NSDragOperation sourceDragMask = [sender draggingSourceOperationMask];
       
    if ( [[pboard types] containsObject:MGSParameterViewPBoardType] ) {
        if ([object isKindOfClass:[MGSParameterViewController class]]) {

            MGSParameterViewController *viewController = object;
            NSAssert([_viewControllers containsObject:viewController], @"bad view controller");
            
            //if (sourceDragMask & NSDragOperationGeneric) {
            
            if (!viewController.dragging) {
                viewController.isDragTarget = NO;
            }
            //}
        } else if ([object isKindOfClass:[MGSParameterEndViewController class]]) {
            MGSParameterEndViewController *endViewController = object;
            
            endViewController.isDragTarget = NO;
        }
    }
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
	
    MGSParameterViewController *viewController = (MGSParameterViewController *)controller;
    
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
        BOOL scrollingEnabled = self.parameterScrollingEnabled;
        self.parameterScrollingEnabled = NO;
        self.selectedParameterViewController = viewController;
        self.parameterScrollingEnabled = scrollingEnabled;
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
#pragma mark Undo support

/*
 
 - registerUndoForObject:actionName:
 
 */
- (void)registerUndoForObject:(id)object
{
    if (![parameterInputUndoManager isUndoing]) {
        
        @try {
            if (!self.undoActionOperation) {
                [NSException raise:MGSInputParameterUndoException format:@"Cannot register for undo. Operation undefined."];
            }
            
            if (!self.undoActionName) {
                self.undoActionName = NSLocalizedString(@"Input Action", @"Unknown input parameter action");
            }
            
            // build the undo dict
            NSMutableDictionary *undoDict = [NSMutableDictionary dictionaryWithCapacity:4];
            [undoDict setObject:object forKey:@"object"];
            [undoDict setObject:self.undoActionOperation forKey:@"operation"];
            
            // register undo
            [parameterInputUndoManager registerUndoWithTarget:self
                                                     selector:@selector(undoInputParameterChange:)
                                                       object:undoDict];
            
            // undo menu text
            [parameterInputUndoManager setActionName:self.undoActionName];
            
        } @catch (NSException *e) {
            MLogInfo(@"%@ : %@", e.name, e.reason);
        }
    }
    
    self.undoActionOperation = nil;
    self.undoActionName = nil;

    self.canUndo = [parameterInputUndoManager canUndo];
}

/*
 
 - undoInputParameterChange:
 
 */
- (void)undoInputParameterChange:(NSDictionary *)undoDict
{
    // get the original operation to be undone
    NSString *operation = [undoDict objectForKey:@"operation"];
    if (!operation) {
        [NSException raise:MGSInputParameterException format:@"Undo operation is nil."];
    }
    
    // get the undo object
    NSDictionary *objectDict = [undoDict objectForKey:@"object"];
    if (!objectDict) {
        [NSException raise:MGSInputParameterException format:@"Undo object is nil."];
    }
    
    // get changed index and view controller
    MGSParameterViewController *changedViewController = nil;
    NSUInteger changedIndex = NSNotFound;
    if ([objectDict objectForKey:@"changedIndex"]) {
        changedIndex = [[objectDict objectForKey:@"changedIndex"] unsignedIntegerValue];

        if (changedIndex < [_viewControllers count]) {
            changedViewController = [_viewControllers objectAtIndex:changedIndex];
        }
    }

    // get original index
    NSUInteger originalIndex = NSNotFound;
    if ([objectDict objectForKey:@"originalIndex"]) {
        originalIndex = [[objectDict objectForKey:@"originalIndex"] unsignedIntegerValue];
    }

    // get the script parameter
    MGSScriptParameter *scriptParameter = [objectDict objectForKey:@"scriptParameter"];

    [parameterInputUndoManager disableUndoRegistration];

    @try {
        
        // undo delete, close, cut
        if ([operation isEqualToString:@"delete"] || [operation isEqualToString:@"close"] || [operation isEqualToString:@"cut"]) {
            
            if (changedIndex == NSNotFound) {
                [NSException raise:MGSInputParameterException format:@"Controller index is missing for operation : %@", operation];
            }


            if (changedIndex >= [_viewControllers count]) {
                
                // append input
                [self appendInputParameterAction:scriptParameter];
            } else {
                
                if (!changedViewController) {
                    [NSException raise:MGSInputParameterException format:@"Changed view controller is missing for operation : %@", operation];
                }

                 // insert input
                self.selectedParameterViewController = changedViewController;
                [self insertInputParameterAction:scriptParameter];
            }
            
        // undo insert, append, duplicate, paste
        } else if ([operation isEqualToString:@"insert"] || [operation isEqualToString:@"append"]
                   || [operation isEqualToString:@"duplicate"] || [operation isEqualToString:@"paste"]) {
            
            if (!changedViewController) {
                [NSException raise:MGSInputParameterException format:@"Changed view controller is missing for operation : %@", operation];
            }
            
            // close the parameter
            [self closeParameterView:changedViewController];
            
        // undo move
        } else if ([operation isEqualToString:@"move"]) {

            if (changedIndex == NSNotFound || originalIndex == NSNotFound) {
                [NSException raise:MGSInputParameterException format:@"Controller index is missing for operation : %@", operation];
            }

            if (!changedViewController) {
                [NSException raise:MGSInputParameterException format:@"Changed view controller is missing for operation : %@", operation];
            }

             // move the parameter
            [self moveParameterAtIndex:changedIndex toIndex:originalIndex];
            [self scrollViewControllerVisible:changedViewController];
            
            // undo type change
        } else if ([operation isEqualToString:@"type"]) {
            
            if (changedIndex == NSNotFound) {
                [NSException raise:MGSInputParameterException format:@"Controller index is missing for operation : %@", operation];
            }

            [_scriptParameterManager replaceItemAtIndex:changedIndex withItem:scriptParameter];
            
            changedViewController.scriptParameter = scriptParameter;
        } else {
            [NSException raise:MGSInputParameterException format:@"Bad operation undo type found : %@", operation];
        }
    } @catch (NSException *e) {
        
        MLogInfo(@"Exception: %@ : %@", [e name], [e reason]);
        
    } @finally {
        
        [parameterInputUndoManager enableUndoRegistration];
        
    }
    

}

/*
 
 - setUndoActionName:
 
 */
- (void)setUndoActionName:(NSString *)undoActionName
{
    if (!_undoActionName || !undoActionName) {
        _undoActionName = undoActionName;
    }
}

/*
 
 - setUndoActionOperation:
 
 */
- (void)setUndoActionOperation:(NSString *)undoActionOperation
{
    if (!_undoActionOperation || !undoActionOperation) {
        _undoActionOperation = undoActionOperation;
    }
}

#pragma mark -
#pragma mark NSMenuValidation protocol

/*
 
 - validateMenuItem:
 
 */
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    BOOL valid = NO;
    NSString *menuTitle = nil;
    NSString *inputTitle = NSLocalizedString(@"Input", @"Input menu title");
    NSUInteger viewIndex = NSNotFound;
    
    if ([menuItem menu] == inputParameterMenu) {
        if (self.selectedParameterViewController) {
            viewIndex = [_viewControllers indexOfObject:self.selectedParameterViewController];
        }
     }
    
    switch (menuItem.tag) {
        case kMGSParameterInputMenuMoveUp:
            if (self.selectedParameterViewController) {
                valid = (viewIndex == 0 ? NO : YES);
            }
            break;

        case kMGSParameterInputMenuMoveDown:
            if (self.selectedParameterViewController) {
                valid = (viewIndex >= [_viewControllers count] - 1) ? NO : YES;
            }
            break;
           
        case kMGSParameterInputMenuPaste:
            valid = [self canPasteInputParameter];
            menuTitle = NSLocalizedString(@"Paste", @"Paste menu title");
            if (valid) {
                MGSScriptParameter *scriptParameter = [self pasteBoardScriptParameter];
                if (scriptParameter) {
                    
                    MGSParameterPluginController *parameterPluginController = [[NSApp delegate] parameterPluginController];
                    MGSParameterPlugin *parameterPlugin = [parameterPluginController pluginWithClassName:scriptParameter.typeName];
                    
                    if (parameterPlugin) {
                        menuTitle = [NSString stringWithFormat:@"%@ %@ %@", menuTitle, parameterPlugin.menuItemString, inputTitle];
                    }
                }
            }
            break;
        
        case kMGSParameterInputMenuUndo:
            menuTitle = NSLocalizedString(@"Undo", @"undo menu title");
            valid = [parameterInputUndoManager canUndo];
            if (valid) {
                menuTitle = [parameterInputUndoManager undoMenuItemTitle];
            }
            break;


        case kMGSParameterInputMenuAppendType:
        case kMGSParameterInputMenuAppend:
            valid = YES;
            break;
            
        case kMGSParameterInputMenuInsertType:
        case kMGSParameterInputMenuInsert:
        case kMGSParameterInputMenuDuplicate:
        case kMGSParameterInputMenuRemove:
        case kMGSParameterInputMenuCut:
        case kMGSParameterInputMenuCopy:
            valid = self.selectedParameterViewController ? YES : NO;
            break;
            
        default:
            break;
    }
    
    // submenu
    if (menuItem.parentItem) {
        switch (menuItem.parentItem.tag) {
            case kMGSParameterInputMenuAppendType:
                valid = YES;
                break;
                
            case kMGSParameterInputMenuInsertType:
                valid = self.selectedParameterViewController ? YES : NO;
                break;
                
            default:
                break;
        }
    }
    
    if (menuTitle) {
        [menuItem setTitle:menuTitle];
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
    
    NSUInteger changedIndex = [_viewControllers indexOfObject:targetViewController];

    [parameterInputUndoManager disableUndoRegistration];

    MGSScriptParameter *scriptParameter = nil;
    
    // if sender is a script parameter then use it
    if ([sender isKindOfClass:[MGSScriptParameter class]]) {
        scriptParameter = [(MGSScriptParameter *)sender mutableDeepCopy];
    }

    // insert parameter
    MGSParameterViewController *sourceViewController = [self insertScriptParameter:scriptParameter AtIndex:changedIndex];
    
    [parameterInputUndoManager enableUndoRegistration];

    // select new view
    self.selectedParameterViewController = sourceViewController;

    // register undo
    self.undoActionName = NSLocalizedString(@"Insert Input", @"Parameter Insert undo");
    self.undoActionOperation = @"insert";
    NSDictionary *undoObject = @{ @"changedIndex" : @(changedIndex), @"scriptParameter" : sourceViewController.scriptParameter.mutableDeepCopy};
    [self registerUndoForObject:undoObject];

}


/*
 
 - appendInputParameterAction:
 
 */
- (IBAction)appendInputParameterAction:(id)sender
{
#pragma unused(sender)
    
    if (![self commitPendingEdits]) return;
    
    [parameterInputUndoManager disableUndoRegistration];
    
    // create parameter
    MGSParameterViewController *parameterViewController = [self appendParameter];

    NSUInteger changedIndex = [_viewControllers count] - 1;

    // if sender is a script parameter then use it
    if ([sender isKindOfClass:[MGSScriptParameter class]]) {
        
        
        NSUInteger targetIndex = [_viewControllers indexOfObject:parameterViewController];
        
        // copy the script parameter and update the manager
        MGSScriptParameter *scriptParameter = [(MGSScriptParameter *)sender mutableDeepCopy];
        [_scriptParameterManager replaceItemAtIndex:targetIndex withItem:scriptParameter];
        
        parameterViewController.scriptParameter = scriptParameter;
        
    }

    [parameterInputUndoManager enableUndoRegistration];

    // select new view
    self.selectedParameterViewController = parameterViewController;
    
    // register undo
    self.undoActionName = NSLocalizedString(@"Append Input", @"Parameter Append undo");
    self.undoActionOperation = @"append";
    NSDictionary *undoObject = @{ @"changedIndex" : @(changedIndex), @"scriptParameter" : parameterViewController.scriptParameter.mutableDeepCopy};
    [self registerUndoForObject:undoObject];
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
    
    [parameterInputUndoManager disableUndoRegistration];

    // insert parameter and set scriptParameter
    [self insertInputParameterAction:self.selectedParameterViewController.scriptParameter];

    [parameterInputUndoManager enableUndoRegistration];

    MGSParameterViewController *viewController = self.selectedParameterViewController;
    viewController.parameterName = [NSString stringWithFormat:@"%@ %@",
                                    viewController.parameterName,
                                    NSLocalizedString(@"copy", @"parameter copy suffix")];
    
    NSUInteger changedIndex = [_viewControllers indexOfObject:self.selectedParameterViewController];

    // register undo
    self.undoActionName = NSLocalizedString(@"Duplicate Input", @"Parameter duplicate undo");
    self.undoActionOperation = @"duplicate";
    NSDictionary *undoObject = @{ @"changedIndex" : @(changedIndex), @"scriptParameter" : viewController.scriptParameter.mutableDeepCopy};
    [self registerUndoForObject:undoObject];
    
}

/*
 
 - removeInputParameterAction:
 
 */
- (IBAction)removeInputParameterAction:(id)sender
{
#pragma unused(sender)
    if (![self commitPendingEdits]) return;
    
    if (self.selectedParameterViewController) {
        self.undoActionName = NSLocalizedString(@"Delete Input", @"Parameter delete undo");
        self.undoActionOperation = @"delete";
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

    [parameterInputUndoManager disableUndoRegistration];
	
    // insert parameter
    self.parameterScrollingEnabled = NO;
    [self insertInputParameterAction:self];
    if (viewController != self.selectedParameterViewController) {
         [self.selectedParameterViewController selectParameterTypeWithMenuTag:[sender tag]];
    }
    [parameterInputUndoManager enableUndoRegistration];
    
    self.parameterScrollingEnabled = YES;
    [self scrollViewControllerVisible:self.selectedParameterViewController];
    
    NSUInteger changedIndex = [_viewControllers indexOfObject:self.selectedParameterViewController];
    
    // register undo
    self.undoActionName = NSLocalizedString(@"Insert Input", @"Parameter insert undo");
    self.undoActionOperation = @"insert";
    NSDictionary *undoObject = @{ @"changedIndex" : @(changedIndex), @"scriptParameter" : self.selectedParameterViewController.scriptParameter.mutableDeepCopy};
    [self registerUndoForObject:undoObject];    
}

/*
 
 - inputParameterAppendMenuAction
 
 */
- (void)inputParameterAppendMenuAction:(id)sender
{
    if (![self commitPendingEdits]) return;
    
    // get selection - nil is okay as we may call this method when no views yet defined.
    MGSParameterViewController *viewController = self.selectedParameterViewController;

    [parameterInputUndoManager disableUndoRegistration];

    // append parameter
    self.parameterScrollingEnabled = NO;
    [self appendInputParameterAction:self];
    if (viewController != self.selectedParameterViewController) {
        [self.selectedParameterViewController selectParameterTypeWithMenuTag:[sender tag]];
    }
    self.parameterScrollingEnabled = YES;
    [self scrollViewControllerVisible:self.selectedParameterViewController];

    [parameterInputUndoManager enableUndoRegistration];

    NSUInteger changedIndex = [_viewControllers indexOfObject:self.selectedParameterViewController];

    // register undo
    self.undoActionName = NSLocalizedString(@"Append Input", @"Parameter append undo");
    self.undoActionOperation =  @"append";
    NSDictionary *undoObject = @{ @"changedIndex" : @(changedIndex), @"scriptParameter" : self.selectedParameterViewController.scriptParameter.mutableDeepCopy};
    [self registerUndoForObject:undoObject];
}
/*
 
 - cutInputParameterAction:
 
 */
- (IBAction)cutInputParameterAction:(id)sender
{
#pragma unused(sender)
    
    if (self.selectedParameterViewController) {
        [self copyInputParameterAction:self];
        
        self.undoActionName = NSLocalizedString(@"Cut Input", @"Parameter cut undo");
        self.undoActionOperation = @"cut";
        [self closeParameterView:self.selectedParameterViewController];
    }
}

/*
 
 - copyInputParameterAction:
 
 */
- (IBAction)copyInputParameterAction:(id)sender
{
#pragma unused(sender)
    
    if (![self commitPendingEdits]) return;
    
    // get selection
    MGSParameterViewController *viewController = self.selectedParameterViewController;
    if (!viewController) return;

    // the parameter model only updates on request
    [viewController updateModel];
    
    NSPasteboard *pasteBoard = [NSPasteboard pasteboardWithName:MGSInputParameterPBoard];
    [pasteBoard clearContents];
    
    NSDictionary *parameterDict = viewController.scriptParameter.dict;
    [pasteBoard declareTypes:@[MGSInputParameterPBoardType] owner:self];
    [pasteBoard setPropertyList:parameterDict forType:MGSInputParameterPBoardType];
    
    // no undo required
}


/*
 
 - pasteInputParameterAction:
 
 */
- (IBAction)pasteInputParameterAction:(id)sender
{
#pragma unused(sender)
    
    if (![self commitPendingEdits]) return;
    
    if ([_viewControllers count] == 0) {
        [self pasteAppendInputParameterAction:sender];
    } else if ([self canPasteInputParameter]) {

        // configure undo
        self.undoActionName = NSLocalizedString(@"Paste Input", @"Parameter paste undo");
        self.undoActionOperation = @"paste";

        MGSScriptParameter *scriptParameter = [self pasteBoardScriptParameter];
        [self insertInputParameterAction:scriptParameter];

    }
}

/*
 
 - pasteAppendInputParameterAction:
 
 */
- (IBAction)pasteAppendInputParameterAction:(id)sender
{
#pragma unused(sender)
    
    if (![self commitPendingEdits]) return;
    
    if ([self canPasteInputParameter]) {
        
        // configure undo
        self.undoActionName = NSLocalizedString(@"Paste Input", @"Parameter paste undo");
        self.undoActionOperation =  @"paste";

        MGSScriptParameter *scriptParameter = [self pasteBoardScriptParameter];
        [self appendInputParameterAction:scriptParameter];
        
    }
}

/*
 
 - undoInputParameterAction:
 
 */
- (IBAction)undoInputParameterAction:(id)sender
{
#pragma unused(sender)
    
    if (![self commitPendingEdits]) return;

    [parameterInputUndoManager undo];
    
    // no undo
}
#pragma mark -
#pragma mark Cut and paste

/*
 
 - cutAndPastePasteBoard
 
 */
- (NSPasteboard *)cutAndPastePasteBoard
{
    return [NSPasteboard pasteboardWithName:MGSInputParameterPBoard];
}

/*
 
 - canPasteInputParameter
 
 */
- (BOOL)canPasteInputParameter
{
    BOOL canPaste = NO;
    NSArray *pbTypes = [[self cutAndPastePasteBoard] types];
    if ([pbTypes containsObject:MGSInputParameterPBoardType]) {
        canPaste = YES;
    }
 
    return canPaste;
}

/*
 
 - pasteBoardScriptParameter
 
 */
- (MGSScriptParameter *)pasteBoardScriptParameter
{
    MGSScriptParameter *scriptParameter = nil;
    
    if ([self canPasteInputParameter]) {
        
        id plist = [[self cutAndPastePasteBoard] propertyListForType:MGSInputParameterPBoardType];
        
        if (plist && [plist isKindOfClass:[NSDictionary class]]) {
            scriptParameter = [MGSScriptParameter new];
            scriptParameter.dict = [NSMutableDictionary dictionaryWithDictionary:plist];
        }
    }
    
    return scriptParameter;
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
            position = NSWindowAbove;
        } else {
            position = NSWindowBelow;
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
			/*_endViewController = [[MGSParameterEndViewController alloc] init];
            _endViewController.view.menu = minimalInputParameterMenu;
            _endViewController.contextPopupButton.menu = minimalInputParameterMenu;
            _endViewController.inputSegmentedControl.target = _;
            _endViewController.inputSegmentedControl.action = @selector(segmentClick);*/
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
    [parameterInputUndoManager disableUndoRegistration];
    
	// create new view
	MGSParameterViewController *viewController = [[MGSParameterViewController alloc] initWithMode:self.mode];
	[viewController setDelegate:self];
	
	// load the view now.
	// sending the view message will trigger view loading.
	// -awakeFromNib will be called before this message returns.
	// lazy loading can lead to lots of problems if it is not anticipated.
	[viewController view];
	
    [[viewController view] registerForDraggedTypes:@[MGSParameterViewPBoardType]];

    [parameterInputUndoManager enableUndoRegistration];

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
	
    // the sizing of inserted parameters is not correct if we don't
    // match the view size to the splitview
    NSSize viewSize = [view frame].size;
    viewSize.width = [splitView frame].size.width;
    [view setFrameSize:viewSize];
    
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
    
    if ([_viewControllers count] > 0) {
        self.selectedParameterViewController = [_viewControllers objectAtIndex:0];
    }
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
