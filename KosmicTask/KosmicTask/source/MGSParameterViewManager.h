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

enum _MGSParameterInputMenuTags {
    kMGSParameterInputMenuInsert = 0,
    kMGSParameterInputMenuAppend = 1,
    kMGSParameterInputMenuDuplicate = 2,
    kMGSParameterInputMenuMoveUp = 3,
    kMGSParameterInputMenuMoveDown = 4,
    kMGSParameterInputMenuRemove = 5,
    kMGSParameterInputMenuInsertType = 6,
    kMGSParameterInputMenuAppendType = 7,
    kMGSParameterInputMenuCut = 8,
    kMGSParameterInputMenuCopy = 9,
    kMGSParameterInputMenuPaste = 10,
    kMGSParameterInputMenuUndo = 11,
};

@protocol MGSParameterViewManager

@required
//- (void)parameterView:(MGSParameterViewController *)viewController resizeViewWithNewSize:(NSSize)newSize;

@optional
- (void)parameterViewDidClose:(MGSParameterViewController *)viewController;
- (void)parameterViewAdded:(MGSParameterViewController *)viewController;
@end

@interface MGSParameterViewManager : NSObject <MGSActionViewController, MGSParameterViewController> {
	IBOutlet MGSParameterSplitView *splitView;
	NSView *_splitSubView2;
	BOOL _nibLoaded;
	NSMutableArray *_viewControllers;
	//NSMutableArray *_viewControllerCache;
	MGSScriptParameterManager * _scriptParameterManager;
	MGSParameterMode _mode;
	IBOutlet MGSParameterEndViewController *_endViewController;
	id _delegate;
	MGSActionViewController *_actionViewController;
    BOOL _dragging;
    NSPoint _lastDragLocation;
    IBOutlet NSMenu *inputParameterMenu;
    IBOutlet NSMenu *minimalInputParameterMenu;
    MGSParameterViewController *_selectedParameterViewController;
    BOOL _parameterScrollingEnabled;
    NSUndoManager *parameterInputUndoManager;
    NSString *_undoActionName;
    NSString *_undoActionOperation;
    NSTimer *_draggingAutoscrollTimer;
    BOOL _canUndo;
}

- (BOOL)commitPendingEdits;
//- (void)updateViews;
- (MGSParameterViewController *)appendParameter;
- (void)selectParameter:(MGSParameterViewController *)controller;
- (void)setScriptParameterManager:(MGSScriptParameterManager *)aScriptParameterHandler;
- (BOOL)validateParameters:(MGSParameterViewController **)parameterViewController;
- (void)selectParameterAtIndex:(NSUInteger)index;
- (void)resetToDefaultValue;
- (void)setHighlightForAllViews:(BOOL)aBool;
- (void)highlightActionView;
- (void)scrollViewControllerVisible:(MGSParameterViewController *)viewController;;

- (IBAction)insertInputParameterAction:(id)sender;
- (IBAction)appendInputParameterAction:(id)sender;
- (IBAction)duplicateInputParameterAction:(id)sender;
- (IBAction)removeInputParameterAction:(id)sender;
- (IBAction)moveUpInputParameterAction:(id)sender;
- (IBAction)moveDownInputParameterAction:(id)sender;
- (IBAction)cutInputParameterAction:(id)sender;
- (IBAction)copyInputParameterAction:(id)sender;
- (IBAction)pasteInputParameterAction:(id)sender;
- (IBAction)pasteAppendInputParameterAction:(id)sender;
- (IBAction)undoInputParameterAction:(id)sender;

@property MGSParameterMode mode;
@property id delegate;
@property MGSActionViewController *actionViewController;
@property MGSParameterViewController *selectedParameterViewController;
@property BOOL canUndo;

@end
