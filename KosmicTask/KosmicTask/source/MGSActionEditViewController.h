//
//  MGSActionEditViewController.h
//  Mother
//
//  Created by Jonathan on 01/03/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSActionParameterEditViewController.h"

@class MGSActionDetailEditViewController;
@class MGSActionParameterEditViewController;
@class MGSTaskSpecifier;
@class MGSActionViewController;
@class MGSFlippedView;

@interface MGSActionEditViewController : NSViewController {
	IBOutlet MGSActionDetailEditViewController *actionDetailController;
	IBOutlet MGSActionParameterEditViewController *actionParameterController;	
	IBOutlet NSSplitView *splitView;				// points to same view as NSViewController -view
	IBOutlet NSScrollView *actionDetailScrollView;	// scrollview to hold action detail
	IBOutlet MGSFlippedView *actionFlippedView;	// wrap the action view in this so that it remains at top of scroll view
	IBOutlet NSView *actionParameterEditView;
	IBOutlet NSImageView *dragThumb;

	MGSActionViewController *_actionViewController;	// action controller
	MGSTaskSpecifier *_action;
	
	BOOL _nibLoaded;
}

@property (strong) MGSTaskSpecifier *action;

- (BOOL)commitPendingEdits;
- (void)dispose;
- (MGSParameterViewConfigurationFlags)parameterViewConfigurationFlags;
- (void)setParameterViewConfigurationFlags:(MGSParameterViewConfigurationFlags)flag;
@end
