//
//  MGSParameterViewController.m
//  Mother
//
//  Created by Jonathan on 05/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
/*Initializing View Instances Created in Interface Builder
 View instances that are created in Interface Builder don't call initWithFrame: when their nib files are loaded, 
 which often causes confusion. Remember that Interface Builder archives an object when it saves a nib file, 
 so the view instance will already have been created and initWithFrame: will already have been called.
 
 The awakeFromNib method provides an opportunity to provide initialization of a view when it is created as 
 a result of a nib file being loaded. When a nib file that contains a view object is loaded, each view 
 instance receives an awakeFromNib message when all the objects have been unarchived. 
 This provides the object an opportunity to initialize any attributes that are not archived with 
 the object in Interface Builder. The DraggableItemView class is extremely simple, and doesn't implement awakeFromNib.
 
 There are two exceptions to the initWithFrame: behavior when creating view instances in Interface Builder. 
 Its important to understand these exceptions to ensure that your views initialize properly.
 
 If you have not created an Interface Builder palette for your custom view, there are two techniques
 you can use to create instances of your subclass within Interface Builder. The first is using the Custom 
 View proxy item in the Interface Builder containers palette. This view is a stand-in for your custom view,
 allowing you to position and size the view relative to other views. You then specify the subclass of NSView 
 that the view represents using the inspector. When the nib file is loaded by the application, the custom view
 proxy creates a new instance of the specified view subclass and initializes it using the initWithFrame: method,
 passing along any autoresizing flags as necessary. The view instance then receives an awakeFromNib message.
 
 The second technique is to specify a custom class is used when your custom view subclass inherits from a view
 that Interface Builder provides support for directly. For example, you can create an NSScrollView instance in
 Interface Builder and specify that a custom subclass (MyScrollView) should be used instead, again using the inspector.
 In this case, when the nib file is loaded by the application, the view instance has already been created and the 
 MyScrollView implementation of initWithFrame: is never called. 
 The MyScrollView instance receives an awakeFromNib message and can configure itself accordingly.
 */

#import "MGSMother.h"
#import "MGSParameterViewController.h"
#import "MGSParameterView.h"
#import "MGSParameterViewManager.h"
//#import "MGSScriptParameter.h"
#import "MGSParameterSubEditViewController.h"
#import "MGSParameterSubInputViewController.h"
#import "NSView_Mugginsoft.h"
#import "MGSParameterPluginController.h"
#import "MGSParameterPlugin.h"
#import "MGSAppController.h"
#import "MGSDescriptionViewController.h"
#import "MGSScriptParameter.h"
#import "MGSNotifications.h"
#import "MGSImageAndTextCell.h"
#import "MGSParameterPluginInputViewController.h"
#import "MGSViewDraggingProtocol.h"


NSString *MGSParameterValueContext = @"MGSParameterValueContext";
NSString *MGSParameterSendAsAttachmentContext = @"MGSParameterAttachmentContext";
NSString *MGSResetEnabledContext = @"MGSResetEnabledContext";

// class extension
@interface MGSParameterViewController()
- (void)updateModel:(NSNotification *)notification;
- (void)subViewDidResize:(NSView *)aSubview oldSize:(NSSize)oldSize;
- (void)subview:(NSView *)view wantsNewSize:(NSSize)newSize;
@end

@interface MGSParameterViewController (Private)
- (void)layoutViewForMode;
- (void)setFrameSize:(NSSize)size;
- (void)setParameterPlugin:(MGSParameterPlugin *)plugin;
- (void)setScriptParameterForPlugin:(MGSParameterPlugin *)plugin;
@end


@implementation MGSParameterViewController

#pragma mark -
#pragma mark Properties
@synthesize displayIndex = _displayIndex;
@synthesize scriptParameter = _scriptParameter;
@synthesize parameterType = _parameterType;
@synthesize mode = _mode;
@synthesize parameterName = _parameterName;
@synthesize resetEnabled = _resetEnabled;
@synthesize parameterDescription = _parameterDescription;
@synthesize canDecreaseDisplayIndex = _canDecreaseDisplayIndex;
@synthesize canIncreaseDisplayIndex = _canIncreaseDisplayIndex;
@synthesize dragging = _dragging;

#pragma mark -
#pragma mark Class methods

/*
 
 + parameterTypeMenuDictionaryWithTarget:action:
 
 */
+ (id)parameterTypeMenuDictionaryWithTarget:(id)target action:(SEL)action
{
    NSMenu *popupMenu = [[NSMenu alloc] initWithTitle:@"Format"];
	NSMenuItem *defaultMenuItem = nil;
	
    NSUInteger tag = 900;
    
	// build the parameter menu
	MGSParameterPluginController *parameterPluginController = [[NSApp delegate] parameterPluginController];
	for (id item in [parameterPluginController instances]) {
		
		// sanity check on plugin class
		if ([item isKindOfClass:[MGSParameterPlugin class]]) {
			MGSParameterPlugin *parameterPlugin = item;
			
			// create menu item
			NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[parameterPlugin menuItemString] action:action keyEquivalent:@""];
			[menuItem setTarget:target];
            [menuItem setTag:tag++];
            
			// represented object is our parameter plugin
			[menuItem setRepresentedObject:parameterPlugin];
			
			// add item to popup menu
			[popupMenu addItem:menuItem];
            
            // get default
			if ([parameterPlugin isDefault]) {
				defaultMenuItem = menuItem;
			}
		} else {
			MLog(DEBUGLOG, @"bad parameter plugin class");
		}
	}
    
    return @{@"menu" : popupMenu, @"default" : defaultMenuItem};
}

#pragma mark -
#pragma mark Instance handling
/*
 
 init with mode
 
 this is the designated initialiser
 
 */
-(id)initWithMode:(MGSParameterMode)mode
{
	if ((self = [super initWithNibName:@"ParameterView" bundle:nil])) {
		self.parameterType = MGSNumberParameter;
		_mode = mode;
		self.bannerLeft = @"";
		self.bannerRight = @"";
		_initialTypePluginLoaded = NO;
		_selfLayoutSize = NSZeroSize;
		_topLayoutSize = NSZeroSize;
		_middleLayoutSize = NSZeroSize;
		_bottomLayoutSize = NSZeroSize;
		_layoutHasOccurred = NO;
		_resetEnabled = NO;
		_parameterDescription = nil;
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateModel:) name:MGSNoteEditWindowUpdateModel object:nil];

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
	
	[[self.bannerRightLabel cell] setBackgroundColor:[MGSImageAndTextCell countColor]];
	
	// create description view controller with appropriate mode
	_descriptionViewController = [[MGSParameterDescriptionViewController alloc] initWithMode:self.mode];
	[_descriptionViewController setDelegate:self];
	[_descriptionViewController view];	// load the view
	
	// if the script parameter has been set we need
	// to establish the bindings
	if (_scriptParameter) {
		MGSScriptParameter *scriptParameter = _scriptParameter;
		_scriptParameter = nil;
		[self setScriptParameter:scriptParameter];
	}
	
	// bind it
	//[typePopup bind:NSSelectedIndexBinding toObject:self withKeyPath:@"parameterType" options:nil];
	[self.bannerLeftLabel bind:NSValueBinding toObject:self withKeyPath:@"bannerLeft" options:nil];
	[self.bannerRightLabel bind:NSValueBinding toObject:self withKeyPath:@"bannerRight" options:nil];
	
	// replace the bottom view
	[[self view] replaceSubview:self.bottomView withViewFrameAsOld:[_descriptionViewController view]];
	self.bottomView = [_descriptionViewController view];
	
	// needed to ensure correct view repositioning 
	[self cacheMiddleViewTopYOffset];
	
	// layout the view for the mode.
	// note that the mode is readonly.
	[self layoutViewForMode];
	
	// build menus
	[self buildMenus];
    
    BOOL canChangeParameterIndex = NO;
    switch (_mode) {
        case MGSParameterModeInput:
            break;
            
        case MGSParameterModeEdit:
            canChangeParameterIndex = YES;
            break;
    }
    [parameterIndexControl setHidden:!canChangeParameterIndex];
    
    self.canDecreaseDisplayIndex = NO;
    self.canDecreaseDisplayIndex = NO;
    
}


#pragma mark -
#pragma mark View handling
/*
 
 parameter view
 
 */
- (MGSParameterView *)parameterView
{
	if ([[self view] isKindOfClass:[MGSParameterView class]]) {
		return (MGSParameterView *)[self view];
	} else {	
		return nil;
	}
}

/*
 
 close the view
 
 */
- (IBAction)close:(id)sender
{
	#pragma unused(sender)
	
	if (self.delegate && [self.delegate respondsToSelector:@selector(closeParameterView:)]) {
		[self.delegate closeParameterView:self];
	}
}

#pragma mark -
#pragma mark Validation
/*
 
 is valid
 
 */
- (BOOL)isValid
{
	if (_typeInputViewController) {
		return [_typeInputViewController isValid];
	}
	
	return YES;
}

/*
 
 validation string
 
 */
- (NSString *)validationString
{
	if (_typeInputViewController) {
		return [_typeInputViewController validationString];
	}
	
	return nil;
}

#pragma mark -
#pragma mark Accessors

/*
 
 - setCanDecreaseDisplayIndex:
 
 */
- (void)setCanDecreaseDisplayIndex:(BOOL)value
{
    _canDecreaseDisplayIndex = value;

    [parameterIndexControl setEnabled:_canDecreaseDisplayIndex forSegment:kMGSParameterIndexDecrease];
}

/*
 
 - setCanIncreaseDisplayIndex:
 
 */
- (void)setCanIncreaseDisplayIndex:(BOOL)value
{
    _canIncreaseDisplayIndex = value;
    [parameterIndexControl setEnabled:_canIncreaseDisplayIndex forSegment:kMGSParameterIndexIncrease];
}

#pragma mark -
#pragma mark Actions

/*
 
 - changeInputIndexAction:
 
 */
- (IBAction)changeInputIndexAction:(id)sender
{
#pragma unused(sender)
    
    MGSParameterIndexChange indexChange = [parameterIndexControl selectedSegment];

    if ([self.delegate respondsToSelector:@selector(parameterViewController:changeIndex:)]) {
        [self.delegate parameterViewController:self changeIndex:indexChange];
    }

}


#pragma mark -
#pragma mark Methods

/*
 
 - updateModel
 
 */
- (void)updateModel
{
    if (MGSParameterModeEdit == _mode) {
		[_typeEditViewController updatePlist];
    } else {
		[_typeInputViewController updatePlist];
	}
}

/*
 
 - markModelDataAsModified
 
 */
- (void)markModelDataAsModified
{
    if (MGSParameterModeEdit == _mode) {
		_typeEditViewController.modelDataModified = YES;
    } 
}
/*
 
 reset input parameter
 
 */
- (void)resetToDefaultValue
{
	if (_typeInputViewController) {
		[_typeInputViewController resetToDefaultValue];
	}
}


/*
 
 set script parameter
 
 */
- (void)setScriptParameter:(MGSScriptParameter *)aScriptParameter
{
	if (_scriptParameter) {
		[name unbind:@"value"];
		[type unbind:@"value"]; // note type_ as type gives compiler error
		[self setRepresentedObject: nil];
	}
	_scriptParameter = aScriptParameter;
		
	// if the nib is not yet loaded then it is pointless
	// to continue with the binding.
	// this problem probably wouldn't occur if the bindings were established in the nib
	// as the views and the toObject (either in the nib or file's owner) be available
	if (!_scriptParameter) {
		return;
	}

	// if script parameter already has a value then we will need to override
	// the parameters default value
	id initialParameterValue = [_scriptParameter valueOrNil];
	
	//
	// set up the bindings
	// This can be done in IB of course but at least here I can see what is going on
	// and change the binding if needs be.
	// And there is less cause of a stray mouse click causing havoc.
	// But see above for nib loading effects
	//
	[self setRepresentedObject: _scriptParameter];
	[_descriptionViewController setRepresentedObject:_scriptParameter];

	self.bannerLeft = self.parameterName;
	
	[name bind:NSValueBinding toObject:self withKeyPath:@"parameterName" options:nil];

	// get required plugin classname from the script parameter
	NSString *pluginClassName = [_scriptParameter typeName];

	// get the required plugin
	MGSParameterPluginController *parameterPluginController = [[NSApp delegate] parameterPluginController];
	MGSParameterPlugin *plugin = [parameterPluginController pluginWithClassName:pluginClassName];
	if (!plugin) {
		MLogInfo(@"Plugin not found: %@. Default will be loaded.", pluginClassName);
		
		// select default plugin
		plugin = [parameterPluginController defaultPlugin];
	}
	
	// select required plugin in popup button
	if (plugin) {
		NSInteger idx = [typePopup indexOfItemWithRepresentedObject:plugin];
		[typePopup selectItemAtIndex:idx];
		[self typePopupMenuItemSelected:[typePopup selectedItem]];
	} else {
		MLogInfo(@"No valid plugin could be loaded.");
	}

	// if an initial value exists and the a type input view controller is available
	// then set the initial parameter value. this effectively overrides the default parameter.
	// this is most likely to occur when a request view is duplicated and the existing values of the
	// parameters need to copied to the new view
	if (initialParameterValue && _typeInputViewController) {
		_typeInputViewController.parameterValue = initialParameterValue;
	}
}

/*
 
 setValue:forKeyPath
 
 this will be called by the binding machinery to
 modify the model data
 
*/
- (void)setValue:(id)value forKeyPath:(NSString *)keyPath
{
	[super setValue:value forKeyPath:keyPath];
	[[[self view] window] setDocumentEdited:YES];
}

/*
 
 update model notification
 
 */
- (void)updateModel:(NSNotification *)notification
{ 
    if ([notification object] == [[self view] window]) {
		
		// when save the script parameter do want to save the current value as it will only
		// override the default when loaded
		[_scriptParameter setValue:nil];
	}
}
/*
 
 set parameter mode
 
 */
/*
- (void)setMode:(MGSParameterMode)mode
{
	_mode = mode;	
	[self view];
	//[self layoutViewForMode];
	_descriptionViewController.mode = _mode;
}
 */


/*
 
 set parameter name
 
 */
- (void)setParameterName:(NSString *)value
{
	[_scriptParameter setName:value];
	self.bannerLeft = value;
}

/*
 
 parameter name
 
 */
- (NSString *)parameterName
{
	return [_scriptParameter name];
}

/*
 
 type popup menu item clicked 
 
 */
- (void)typePopupMenuItemClicked:(id)sender
{
	// popup selection is not bound so modify
	// document edit state manually on click
	[[[self view] window] setDocumentEdited:YES];
	
	[self typePopupMenuItemSelected:sender];
}

/*
 
 - selectParameterTypeWithMenuTag:
 
 */
- (void)selectParameterTypeWithMenuTag:(NSUInteger)tag
{
    [typePopup selectItemWithTag:tag];
    [self typePopupMenuItemSelected:[typePopup.menu itemWithTag:tag]];
}

/*
 
 type popup menu item selected 
 
 */
- (void)typePopupMenuItemSelected:(id)sender
{   
    [self commitEditing];
    
	if (![sender respondsToSelector:@selector(representedObject)]) {
		return;
	}

    if ([self.delegate respondsToSelector:@selector(parameterViewControllerTypeWillChange:)]) {
        [self.delegate parameterViewControllerTypeWillChange:self];
    }
    
    BOOL updateParameterDescription = NO;
    if ([[_scriptParameter description] isEqualToString:self.parameterDescription]) {
        updateParameterDescription = YES;
    }
    
	// the represented object is a plugin which will
	// determine the parameter type
	id representedObject = [sender representedObject];
	MGSParameterPlugin *plugin = representedObject;
	
	[self setParameterPlugin:plugin];
	
	// change parameter description if not edited
	NSString *descripton = self.parameterDescription;
	if (!descripton) {
		descripton = [MGSScriptParameter defaultDescription];
	}
    if (![_scriptParameter description] || [[_scriptParameter description] isEqualToString:@""] || updateParameterDescription) {
        [_scriptParameter setDescription:descripton];
    }
    
    if ([self.delegate respondsToSelector:@selector(parameterViewControllerTypeDidChange:)]) {
        [self.delegate parameterViewControllerTypeDidChange:self];
    }
}

/*
 
 - markParameterNameAsCopy
 
 */
- (void)markParameterNameAsCopy
{
    self.parameterName = [NSString stringWithFormat:@"%@ %@",
                                    self.parameterName,
                                    NSLocalizedString(@"copy", @"parameter copy suffix")];

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
	
	if (context == &MGSParameterValueContext) {
		
		// set script parameter value
		[_scriptParameter setValue: _typeInputViewController.parameterValue];
		
	} else if (context == &MGSParameterSendAsAttachmentContext) {
		
		// send parameter as attachment
		[_scriptParameter setSendAsAttachment:_typeInputViewController.sendAsAttachment];
		
	} else if (context == &MGSResetEnabledContext) {
		[self willChangeValueForKey:@"resetEnabled"];
		_resetEnabled = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
		[self didChangeValueForKey:@"resetEnabled"];
		
		SEL resetEnabled = @selector(parameterViewController:didChangeResetEnabled:);
		if (self.delegate && [self.delegate respondsToSelector:resetEnabled]) {
			[self.delegate parameterViewController:self didChangeResetEnabled:_resetEnabled];
		}
	}
}

// NOTE: NSViewController does it all.
// implement the NSEditor protocol
/*
 Note the following binding constant:
 
 NSContinuouslyUpdatesValueBindingOption
 An NSNumber object containing a Boolean value that determines whether the value of the binding is updated as edits are made to the user interface item or is updated only when the user interface item resigns as the responder.
 
 Available in Mac OS X v10.4 and later.
 
 Declared in NSKeyValueBinding.h
 
 So a textview will not be updated without this option unless it resigns first responder.
 When a user clicks a button the button does NOT become first responder.
 Sof the text field does not update its binding.
 Hence the NSEditorRegistration protocol which can be used to detetect uncommitted edits.
 
 Not that this protocol forms part of the whole binding methodology.
 You sort of have to implement all of it. Which includes NSEditorRegistration

 */
/*
- (void)objectDidBeginEditing:(id)editor
{
	_editor = editor;
}

- (void)objectDidEndEditing:(id)editor
{
	_editor = nil;
}

// not sure that this is correct? NSViewController might handle it;
- (BOOL)commitPendingEdits
{
	if (_editor) {
		return [_editor commitEditing];
	}
	return YES;
}
 */
// NSTextField delegate

// control text edit ending also triggers a focus ring redraw
// and hence need for parameterview redraw
/*
- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
	[parameterView setNeedsDisplay:YES];
}
 */
/*
- (void)controlTextDidBeginEditing:(NSNotification *)aNotification
{
	[parameterView setNeedsDisplay:YES];
}
 */

#pragma mark -
#pragma mark Menus
/*
 
 build menus
 
 */
- (void)buildMenus
{

    NSDictionary *menuDict = [[self class] parameterTypeMenuDictionaryWithTarget:self action:@selector(typePopupMenuItemClicked:)];
    
    NSMenu *popupMenu = [menuDict objectForKey:@"menu"];
    NSMenuItem *defaultMenuItem = [menuDict objectForKey:@"default"];
    
	// set menu for popup
	[typePopup setMenu:popupMenu];
	if (defaultMenuItem) {
		[typePopup selectItem:defaultMenuItem];
		[self typePopupMenuItemSelected:defaultMenuItem];
	}
}

#pragma mark -
#pragma mark MGSRoundedPanelView delegate methods
/*
 
 - mouseDown:
 
 */
- (void)mouseDown:(NSEvent *)theEvent
{
	
	[super mouseDown:theEvent];
	
	NSPoint mouseLoc = [[self view] convertPoint:[theEvent locationInWindow] fromView:nil];	// convert to view co-ordinates
	
	// hit-test the description text
	if (NSMouseInRect(mouseLoc, [[_descriptionViewController view] frame], [[_descriptionViewController view] isFlipped])) {
		[_descriptionViewController toggleDescriptionDisclosure];
	} else {
        
        // hit test banner view for drag source.
        // we only want to drag in edit mode.
        BOOL bannerClick = NSPointInRect(mouseLoc, self.bannerView.frame);
        BOOL requireBannerClick = YES;
        if (!requireBannerClick) bannerClick = YES;
        
        if (bannerClick && MGSParameterModeEdit == _mode) {
            
            if ([self.delegate respondsToSelector:@selector(dragParameterView:event:)]) {
                self.dragging = YES;
                _mouseDragged = NO;
                _lastDragLocation = mouseLoc;
            }
        }
    }
}

/*
 
 - mouseDragged:
 
 */
-(void)mouseDragged:(NSEvent *)event
{
    // delay kicking off the actual drag until we get the first drag event
    if (self.dragging && !_mouseDragged) {
        if ([self.delegate respondsToSelector:@selector(dragParameterView:event:)]) {
            [self.delegate dragParameterView:self event:event];
        }
        _mouseDragged = YES;
    }

    if (self.dragging) {
        NSPoint mouseLoc=[self.view convertPoint:[event locationInWindow]
                                          fromView:nil];
        
                
        // save the new drag location for the next drag event
        _lastDragLocation = mouseLoc;
    }
}

/*
 
 - mouseUp:
 
  
 */
-(void)mouseUp:(NSEvent *)event
{
#pragma unused(event)
    
    if (self.dragging) {
        self.dragging = NO;
    }
    
}

#pragma mark -
#pragma mark MGSViewDraggingProtocol protocol

/*
 
 - draggingEntered:object:
 
 */
- (NSDragOperation)draggingEntered:(id < NSDraggingInfo >)sender object:(id)object
{   
    NSAssert(object == self.view, @"Bad class");
    
    if ([self.delegate respondsToSelector:@selector(draggingEntered:object:)]) {
        return [self.delegate draggingEntered:sender object:self];
    }
    
    return NSDragOperationNone;
}


/*
 
 - draggingUpdated:object:
 
 */
- (NSDragOperation)draggingUpdated:(id < NSDraggingInfo >)sender object:(id)object
{
#pragma unused(object)
   
    if ([self.delegate respondsToSelector:@selector(draggingUpdated:object:)]) {
        return [self.delegate draggingUpdated:sender object:self];
    }

    
    return NSDragOperationNone;
}

/*
 
 - draggingExited:object:
 
 */
- (void)draggingExited:(id < NSDraggingInfo >)sender object:(id)object
{
#pragma unused(object)
    
    if ([self.delegate respondsToSelector:@selector(draggingExited:object:)]) {
        [self.delegate draggingExited:sender object:self];
    }
}

/*
 
 - prepareForDragOperation:object:
 
 */
- (BOOL)prepareForDragOperation:(id < NSDraggingInfo >)sender object:(id)object
{
    #pragma unused(object)
    
    if ([self.delegate respondsToSelector:@selector(prepareForDragOperation:object:)]) {
        return [self.delegate prepareForDragOperation:sender object:self];
    }
    
    return NO;
}

/*
 
 - performDragOperation:object:
 
 */
- (BOOL)performDragOperation:(id < NSDraggingInfo >)sender object:(id)object
{
    #pragma unused(object)
    
    if ([self.delegate respondsToSelector:@selector(performDragOperation:object:)]) {
        return [self.delegate performDragOperation:sender object:self];
    }
    
    return NO;
    
}

/*
 
 - concludeDragOperation:object:
 
 */
- (void)concludeDragOperation:(id < NSDraggingInfo >)sender object:(id)object
{
    #pragma unused(object)
    
    if ([self.delegate respondsToSelector:@selector(concludeDragOperation:object:)]) {
        [self.delegate concludeDragOperation:sender object:self];
    }
    
}

/*
 
 - draggingEnded:object:
 
 */
- (void)draggingEnded:(id < NSDraggingInfo >)sender object:(id)object
{
    #pragma unused(object)
    
    if (self.dragging) {
        self.dragging = NO;
    }
    
    if ([self.delegate respondsToSelector:@selector(draggingEnded:object:)]) {
        [self.delegate draggingEnded:sender object:self];
    }
    
}

#pragma mark -
#pragma mark Subview resizing
/*
 
 - subview:wantsNewSize:
 
 */
- (void)subview:(NSView *)view wantsNewSize:(NSSize)newSize
{
	NSSize oldSize = view.frame.size;
	CGFloat heightDelta = newSize.height - oldSize.height;

	if (([view autoresizingMask] & NSViewHeightSizable)) {
		NSSize size = self.view.frame.size;
		size.height += heightDelta;
		[self setFrameSize:size];
	} else {
		[view setFrameSize:newSize];
		[self subViewDidResize:view oldSize:oldSize];
	}
	
	self.minHeight += heightDelta;
	_middleLayoutSize = [self.middleView frame].size;
	self.minMiddleHeight = _middleLayoutSize.height;
	self.maxMiddleHeight = _middleLayoutSize.height * 5;
	
	// max height
	self.maxHeight += 3 * heightDelta;
	
}

/*
 
 - subViewDidResize:oldSize:
 
 */
- (void)subViewDidResize:(NSView *)aSubview oldSize:(NSSize)oldSize
{
	// calc change in subview height
	CGFloat subviewFrameHeight = [aSubview frame].size.height;
	CGFloat deltaY = subviewFrameHeight - oldSize.height;
	if (fabs(deltaY) < 0.1) {
		return;
	}

	NSRect bannerViewFrame = [self.bannerView frame];
	NSRect topViewFrame = [self.topView frame];
	NSRect middleViewFrame = [self.middleView frame];
	BOOL updateBannerView = NO;
	BOOL updateTopView = NO;
	BOOL updateMiddleView = NO;
	
	// calc new origins for frames
	if (![aSubview isDescendantOf:self.bannerView]) {
		bannerViewFrame.origin.y += deltaY;
		updateBannerView = YES;
	}
	if (![aSubview isDescendantOf:self.topView] && updateBannerView) {
		topViewFrame.origin.y += deltaY;
		updateTopView = YES;
	}
	if (![aSubview isDescendantOf:self.middleView] && updateTopView) {
		middleViewFrame.origin.y += deltaY;
		updateMiddleView = YES;
	} 
	
	// resize the view
	NSSize viewSize = [[self view] frame].size;
	viewSize.height += deltaY;
	[self setFrameSize:viewSize];
	
	// restore view frames
	if (updateBannerView) [self.bannerView setFrame:bannerViewFrame];	
	if (updateTopView)[self.topView setFrame:topViewFrame];	
	if (updateMiddleView) [self.middleView setFrame:middleViewFrame];
	
	[self updateFooterPosition];
	
	[[self view] setNeedsDisplay:YES];
}
#pragma mark -
#pragma mark MGSDescriptionViewController delegate methods
/*
 
 description view did resize
 
 */
- (void)descriptionViewDidResize:(MGSParameterDescriptionViewController *)controller oldSize:(NSSize)oldSize
{
	[self subViewDidResize:controller.view oldSize:oldSize];
}


@end

#pragma mark -
@implementation MGSParameterViewController (Private)

/*
 
 layout view for mode
 
 this message should only be sent once as it modfies the view from its
 initial nib state
 
 */
- (void)layoutViewForMode
{
	NSAssert(NO == _layoutHasOccurred, @"parameter view layout has already occurred");
	
	NSPoint bannerOrigin;
	
	//NSRect bannerViewFrame = [bannerView frame];
	NSRect topViewFrame = [self.topView frame];
	NSRect middleViewFrame = [self.middleView frame];
	NSRect bottomViewFrame = [self.bottomView frame];

	// position banner left label
	bannerOrigin = [self.bannerLeftLabel frame].origin;
	bannerOrigin.x = [bannerLeftImage frame].origin.x + [bannerLeftImage frame].size.width + 3;
	[self.bannerLeftLabel setFrameOrigin:bannerOrigin];
	
	MGSParameterView *parameterView = (MGSParameterView *)[self view];
	
	// input mode
	if (MGSParameterModeInput == _mode) {

		// hide close button
		[closeButton setHidden:YES];		

		// position banner right label
		bannerOrigin = [self.bannerRightLabel frame].origin;
		bannerOrigin.x = [closeButton frame].origin.x + [closeButton frame].size.width - [self.bannerRightLabel frame].size.width;
		[self.bannerRightLabel setFrameOrigin:bannerOrigin];
		
		NSSize viewSize = [[self view] frame].size;

		// hide top view and position options view
		// in its place
		if ([self.topView superview]) {
			[self.topView removeFromSuperview];
			viewSize.height -= topViewFrame.size.height;
		}
		
		// resize the view
		[self setFrameSize:viewSize];
		[[self view] setNeedsDisplay:YES];
		
		// frame the middle view
		[self.middleView setFrame:middleViewFrame];
		[self.middleView setNeedsDisplay:YES];

		// frame the bottom view
		[self.bottomView setFrame:bottomViewFrame];
		[self.bottomView setNeedsDisplay:YES];

		// draw footer around bottom view
		[parameterView setDrawFooter:YES];
		[self updateFooterPosition];
		
	// edit mode	
	} else if (MGSParameterModeEdit == _mode) {
		
		//[parameterView setDrawFooter:NO];

		// show close button
		[closeButton setHidden:NO];

		// position banner right label
		bannerOrigin = [self.bannerRightLabel frame].origin;
		bannerOrigin.x = [closeButton frame].origin.x  - [self.bannerRightLabel frame].size.width;
		[self.bannerRightLabel setFrameOrigin:bannerOrigin];
		
		// don't draw the footer
		[parameterView setDrawFooter:NO];

	} else {
		NSAssert(NO, @"invalid parameter mode");
	}
	
	// thse may not be referenced elsewhere but they may come in useful
	// in the future
	_selfLayoutSize = [[self view] frame].size;
	_topLayoutSize = [self.topView frame].size;
	_middleLayoutSize = [self.middleView frame].size;
	
	// complication here is that we are creating our bottom description view at the
	// size that the bottom view exists at within the nib.
	// for an input view however the min layout size will be reduced to a single line.
	// so we need to ask the description controller waht its initial layout size will be.
	_bottomLayoutSize = [_descriptionViewController initialLayoutSize];
	 
	// set min heights for views
	self.minHeight = _selfLayoutSize.height - [self.bottomView frame].size.height + _bottomLayoutSize.height;
	self.minMiddleHeight = _middleLayoutSize.height;
	self.minBottomHeight = _bottomLayoutSize.height;
	
	// set max heights
	self.maxHeight = _selfLayoutSize.height * 3;
	self.maxMiddleHeight = _middleLayoutSize.height * 3;
	self.maxBottomHeight = _bottomLayoutSize.height * 5;

	_layoutHasOccurred = YES;	
}

/*
 
 set view frame size
 
 */
- (void)setFrameSize:(NSSize)size
{
	[[self view] setFrameSize:size];
	
}

/*
 
 set the parameter plugin
 
 */
- (void)setParameterPlugin:(MGSParameterPlugin *)plugin
{
	// validate the plugins identity.
	if (![plugin isKindOfClass:[MGSParameterPlugin class]]) {
		[MGSError clientCode:MGSErrorCodeParameterPlugin reason:NSLocalizedString(@"Invalid plugin", @"Plugin error message")];
		return;
	}
	
	NSView *newMiddleView = nil;
	
	//
	// attempt to create edit view
	//
	NSViewController *typeViewController;
	if (MGSParameterModeEdit == _mode && [plugin respondsToSelector:@selector(createViewController:delegate:)]) {
		
		// instantiate edit view controller and associated view
		_typeEditViewController = [plugin createViewController:[plugin editViewControllerClass] delegate:self];
		typeViewController = _typeEditViewController;
		newMiddleView = [typeViewController view];
		
		// plist will not be loaded yet so defaults will be returned
		self.canDragHeight = [_typeEditViewController canDragHeight];	// generally YES
		self.canDragMiddleView = [_typeEditViewController canDragMiddleView]; // depends on view functionality
		self.parameterDescription = _typeEditViewController.parameterDescription;
	
        //
        // create input view
        //
	} else if (MGSParameterModeInput == _mode && [plugin respondsToSelector:@selector(createViewController:delegate:)]) {

		// instantiate input view controller and associated view
		_typeInputViewController = [plugin createViewController:[plugin inputViewControllerClass] delegate:nil];
		typeViewController = _typeInputViewController;
		
		// observe the input view controller
		[_typeInputViewController addObserver:self forKeyPath:@"parameterValue" options:0 context:&MGSParameterValueContext];
		[_typeInputViewController addObserver:self forKeyPath:@"sendAsAttachment" options:NSKeyValueObservingOptionInitial context:&MGSParameterSendAsAttachmentContext];
		
		// load the view
		[typeViewController view];
		
		// size of type view in nib.
		// want to maintaiin this size
		NSSize initialTypeViewSize = [[typeViewController view] frame].size;

		
		// plist will not be loaded yet so defaults will be returned
		self.canDragHeight = [_typeInputViewController canDragHeight];	// depends on view functionality
		self.canDragMiddleView = [_typeInputViewController canDragMiddleView];	// generally NO
		self.parameterDescription = _typeInputViewController.parameterDescription;
		
		// input plugin view wrapper
		// the wrapper will provide additional standard controls for the input plugin 
		_pluginInputViewController = [[MGSParameterPluginInputViewController alloc] init];
		_pluginInputViewController.delegate = self;
		_typeInputViewController.delegate = _pluginInputViewController;
		
		/*
		 
		 the middle view is NOT our loaded plugin view.
		 the middle view contains a wrapper that, in turn, contains the plugin view.
		 
		 note that the middleview will autoexpand vertically so that if the plugin view
		 wants to change its size it will have to request a change in the parameterview height.
		 
		 */
		newMiddleView = [_pluginInputViewController view];
		NSView *pluginViewPlaceHolder = [_pluginInputViewController pluginView];
		
		// wrap our view, putting replacing placeholder view with our type view
		CGFloat middleViewHeightDelta = [newMiddleView frame].size.height - [pluginViewPlaceHolder frame].size.height;
		[newMiddleView replaceSubview:pluginViewPlaceHolder withViewFrameAsOld:[typeViewController view]];
		_pluginInputViewController.pluginView = [typeViewController view];
		_pluginInputViewController.parameterPluginViewController = _typeInputViewController;
		[_pluginInputViewController addObserver:self forKeyPath:@"resetEnabled" options:NSKeyValueObservingOptionNew context:&MGSResetEnabledContext];
		
		// size the wrapper so that the embedded type view plugin is present at the same
		// size as in its nib
		NSSize newMiddleViewSize = [self.middleView frame].size;
		newMiddleViewSize.height = initialTypeViewSize.height + middleViewHeightDelta;
		[newMiddleView setFrameSize:newMiddleViewSize];
	} else {
		[MGSError clientCode:MGSErrorCodeParameterPlugin reason:NSLocalizedString(@"Invalid plugin or mode", @"Plugin error message")];
		return;
	}
	
	// calc frame for new middleview
	NSRect frame = [newMiddleView frame];
	NSRect prevFrame = [self.middleView frame];

#ifdef MGS_DEBUG_VIEW_SIZING
    NSLog(@"[newMiddleView frame] w = %f h = %f", frame.size.width, frame.size.height);
    NSLog(@"[self.middleView frame] w = %f h = %f", prevFrame.size.width, prevFrame.size.height);
#endif
    
	CGFloat heightDelta = (frame.size.height - prevFrame.size.height);
	frame.origin = prevFrame.origin;
	frame.size.width = prevFrame.size.width;
	
	// adjust view size
	NSSize viewSize = [[self view] frame].size;
	viewSize.height += heightDelta;
	[self setFrameSize:viewSize];
	
	// replace middle view
    [newMiddleView  setFrame:frame];
	[[self view] replaceSubview:self.middleView with:newMiddleView];
	self.middleView = newMiddleView;
	[self.middleView setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable]; // as coming from plugin ensure resizing is correct
	
	// set middle view frame
	//[self.middleView setFrame:frame];
	[self.middleView setNeedsDisplay:YES];
	[[self view] setNeedsDisplay:YES];
	
	// initialise the view min height of the view on first load
	if (!_initialTypePluginLoaded) {
	}
	
	self.minHeight += heightDelta;
	_middleLayoutSize = [self.middleView frame].size;
	self.minMiddleHeight = _middleLayoutSize.height;
	self.maxMiddleHeight = _middleLayoutSize.height * 5;
	
	// max height
	self.maxHeight += 3 * heightDelta;
	
	[self setScriptParameterForPlugin: plugin];
	
	_initialTypePluginLoaded = YES;
}

/* 
 
 set script parameter for plugin
 

 */
- (void)setScriptParameterForPlugin:(MGSParameterPlugin *)plugin
{
	if (!_scriptParameter) {
		return;
	}
	
	// class name of script parameter must match that
	// of our plugin.
	// note that when loading an existing parameter the type popup
	// will be preset to the script parameter class name.
	// in this way the existing type name and info are preserved.
	NSString *typeName = [_scriptParameter typeName];
	NSString *pluginClassName = [plugin className];
	
	// if our script parameter classname does not match our
	// plugin name then modify our script parameter
	if (![typeName isEqualToString:pluginClassName]) {
		[_scriptParameter setTypeName:pluginClassName];
		[_scriptParameter resetTypeInfo];
	}
	
	// send our class info to our plugin view
	NSMutableDictionary *pluginPlist = [_scriptParameter typeInfo];
	if (MGSParameterModeInput == _mode) {
		[_typeInputViewController setParameterPlist:pluginPlist];
		
		self.canDragHeight = [_typeInputViewController canDragHeight];	// depends on view functionality
		self.canDragMiddleView = [_typeInputViewController canDragMiddleView];	// generally NO
		
	} else if (MGSParameterModeEdit == _mode) {
		[_typeEditViewController setParameterPlist:pluginPlist];
		
		// generally can drag in edit view
		self.canDragHeight = [_typeEditViewController canDragHeight];	// generally YES
		self.canDragMiddleView = [_typeEditViewController canDragMiddleView]; // depends on view functionality
		
	} else {
		NSAssert(NO, @"invalid mode");
	}
}

@end

