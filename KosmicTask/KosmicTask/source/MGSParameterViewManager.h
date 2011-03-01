//
//  MGSParameterViewManager.h
//  Mother
//
//  Created by Jonathan on 06/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSParameterViewController.h"
#import "MGSActionViewController.h"

@class MGSScriptParameterManager;
@class MGSParameterEndViewController;
@class MGSParameterSplitView;


@protocol MGSParameterViewManager

@required
//- (void)parameterView:(MGSParameterViewController *)viewController resizeViewWithNewSize:(NSSize)newSize;

@optional
- (void)parameterViewDidClose:(MGSParameterViewController *)viewController;

@end

@interface MGSParameterViewManager : NSObject <MGSActionViewController, MGSParameterViewController> {
	IBOutlet MGSParameterSplitView *splitView;
	NSView *_splitSubView2;
	BOOL _nibLoaded;
	NSMutableArray *_viewControllers;
	//NSMutableArray *_viewControllerCache;
	MGSScriptParameterManager * _scriptParameterHandler;
	MGSParameterMode _mode;
	MGSParameterEndViewController *_endViewController;
	id _delegate;
	MGSActionViewController *_actionViewController;
}

- (BOOL)commitPendingEdits;
//- (void)updateViews;
- (MGSParameterViewController *)addParameter;
- (void)removeLastParameter;
- (void)highlightParameter:(MGSParameterViewController *)controller;
- (void)setScriptParameterHandler:(MGSScriptParameterManager *)aScriptParameterHandler;
- (BOOL)validateParameters:(MGSParameterViewController **)parameterViewController;
- (void)highlightParameterAtIndex:(NSUInteger)index;
- (void)resetToDefaultValue;
- (void)setHighlightForAllViews:(BOOL)aBool;
- (void)highlightActionView;

@property MGSParameterMode mode;
@property id delegate;
@property MGSActionViewController *actionViewController;
@end
