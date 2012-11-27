//
//  MGSActionParameterEditViewController.m
//  Mother
//
//  Created by Jonathan on 03/03/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSActionParameterEditViewController.h"
#import "MGSTaskSpecifier.h"
#import "MGSNetClient.h"
#import "MGSClientScriptManager.h"
#import "MGSNotifications.h"
#import "MGSScriptParameterManager.h"
#import "MGSScript.h"
#import "MGSScriptPlist.h"
#import "MGSScriptParameter.h"
#import "MGSParameterViewManager.h"
#import "MGSEmptyParameterViewController.h"
#import "NSView_Mugginsoft.h"
#import "MGSParameterSplitView.h"

#define MGSAddItem 0
#define MGSRemoveItem 1

#define ON_RUN_TASK_CALL_IMPLICIT_RUN_HANDLER 0
#define ON_RUN_TASK_CALL_EXPLICIT_RUN_HANDLER_WITH_PARAMETERS 1
#define ON_RUN_TASK_CALL_DEFAULT_HANDLER 2
#define ON_RUN_TASK_CALL_USER_HANDLER 3

NSString *MGSInputCountContext = @"InputContext";

@interface MGSActionParameterEditViewController (Private)
@end



@implementation MGSActionParameterEditViewController
@synthesize inputCount = _inputCount;
@synthesize action = _action;
@synthesize parameterView;

/*
 
 awake from nib
 
 */
- (void)awakeFromNib
{
	//_noSubName = NSLocalizedString(@"(None)", @"No script subroutine to be called");
	_parameterHandler = nil;
	_action = nil;
	
	// set edit mode for parameter view handler
	parameterViewHandler.mode = MGSParameterModeEdit;
	
	// observe the input count
	[self addObserver:self forKeyPath:@"inputCount" options:NSKeyValueObservingOptionNew context:MGSInputCountContext];
	self.inputCount = 0;

	// set empty parameter view
	self.parameterView = [emptyParameterViewController view];
	
}

/*
 
 set parameter view
 note that this will be called during nib loading to set the value of the IBOutlet parameterView.
 when nib loads parameterView and parameterScrollView will point to the same scrollview.
 */
- (void)setParameterView:(NSView *)view
{
	// replace existing parameter view with view
	if (parameterView) {
		
		// check if view already set
		if (parameterView == view) {
			return;
		}
		
		NSRect frame = [parameterView frame];
		[[self view] replaceSubview:parameterView with:view];
		parameterView = view;
		[parameterView setFrame:frame];
		[parameterView setNeedsDisplay:YES];
	} else {
		parameterView = view;
	}
}

/*
 
 observe value for key path
 
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	#pragma unused(keyPath)
	#pragma unused(object)
	#pragma unused(change)
	
	// input count modified
	if (context == MGSInputCountContext) {
		
		// change remove input segment enabled status
		[inputSegmentedControl setEnabled:(self.inputCount == 0) ? NO : YES forSegment:MGSRemoveItem]; 
		
		// show the required parameter view
		[self setParameterView:(self.inputCount == 0) ? [emptyParameterViewController view] : parameterScrollView];
	}
}

/*
 
 set action
 
 */
- (void)setAction:(MGSTaskSpecifier *)anAction
{
	_action = anAction;
	
	// set parameter handler
	_parameterHandler = [_action.script parameterHandler];
	self.inputCount = [_parameterHandler count];
	
	[parameterViewHandler setScriptParameterHandler:_parameterHandler];
	parameterViewHandler.delegate = self;
	  
	// set up bindings
	[inputCountText bind:@"value" toObject:self withKeyPath:@"inputCount" options:nil];

}

- (void)updateParameters
{
}


/*
 
 copy the handler template to the clip board
 
 */
- (IBAction)copyHandlerTemplate:(id)sender
{
	#pragma unused(sender)
	
	[self commitEditing];
	[[[self view] window] makeFirstResponder:nil];	// commitEditing may not be sufficient as control in another view nay be first responder
	
	NSString *handlerTemplate = [[_action script] subroutineTemplate];
	NSPasteboard *pb = [NSPasteboard generalPasteboard];
	NSArray *types = [NSArray arrayWithObjects: NSStringPboardType, nil];
	[pb declareTypes:types owner:self];
	[pb setString:handlerTemplate forType:NSStringPboardType];
}

/*
 
 set subroutine name
 
 */
- (void)setSubroutineName:(NSString *)name
{
	[_action.script setSubroutine:name];
}

/*
  
 subroutine name
 
 */
- (NSString *)subroutineName
{
	return [_action.script subroutine];
}
/*
 
 process item segment control action
 
 */
- (IBAction)segmentClick:(id)sender
{	
	NSInteger selectedSegment = [sender selectedSegment];
	
	[self commitEditing];
	
	switch (selectedSegment) {
			
			// add item
		case MGSAddItem:;
			MGSParameterViewController *viewController = [parameterViewHandler addParameter];
			[parameterViewHandler highlightParameter:viewController];
			
			break;
			
			// remove item
			case MGSRemoveItem:;
			[parameterViewHandler removeLastParameter];

			break;
			
			default:
			return;
	}
	
	self.inputCount = [_parameterHandler count];

	// document edited
	[[[self view] window] setDocumentEdited:YES];
	
	return;
}

#pragma mark MGSParameterViewManager delegate methods
/*
 
 parameter view did close
 
 */
- (void)parameterViewDidClose:(MGSParameterViewController *)viewController
{
	#pragma unused(viewController)
	
	// the view has closed.
	// setting the input count will have no effect other than to reset the
	// bound parameter view counter
	self.inputCount = [_parameterHandler count];
	
	// document edited
	[[[self view] window] setDocumentEdited:YES];
}
@end

@implementation MGSActionParameterEditViewController (Private)
@end
