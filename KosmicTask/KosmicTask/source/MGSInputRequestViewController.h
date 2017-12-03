//
//  MGSInputRequestViewController.h
//  Mother
//
//  Created by Jonathan on 05/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MGSParameterViewManager;
@class MGSActionViewController;
@class MGSScript;
@class MGSTaskSpecifier;
@class MGSTaskSpecifierManager;
@class MGSParameterSplitView;

extern NSString *MGSIsProcessingContext;

@protocol MGSInputRequestViewController

@optional
-(void) closeRequestTab;

@end

@interface MGSInputRequestViewController : NSViewController {
	//IBOutlet NSView *view;
	IBOutlet NSScrollView *scrollView;
	IBOutlet MGSParameterViewManager *_parameterViewManager;
	IBOutlet MGSActionViewController *_actionViewController;
	IBOutlet NSImageView *_splitDragView;
	IBOutlet MGSParameterSplitView* _parameterSplitView;
	
	IBOutlet NSButton *lockButton;
	IBOutlet NSButton *detachButton;
	
	BOOL _allowDetach;
	BOOL _allowLock;
	BOOL _keepActionDisplayed;		// if YES then action will be kept permanently displayed until tab closed 
	BOOL _isProcessing;
	
	IBOutlet NSButton *showPrevAction;
	IBOutlet NSButton *showNextAction;
	IBOutlet NSTextField *positionTextField;
	IBOutlet NSPopUpButton *_actionPopup;
	IBOutlet NSButton *syncActionButton;
	
	BOOL _showPrevActionEnabled;
	BOOL _showNextActionEnabled;
	BOOL _indexMatchesPartnerIndex;
	BOOL _taskResultDisplayLocked;
	
	NSString * _actionPositionString;
	
	id __unsafe_unretained _delegate;
	MGSTaskSpecifierManager *_actionController;	// action history controller
	MGSTaskSpecifier *_action;
	NSInteger _selectedPartnerIndex;
	NSInteger _selectedIndex;
}

- (BOOL)keepActionDisplayed;
- (NSRect)splitViewRect;
- (IBAction)showPreviousAction:(id)sender;
- (IBAction)showNextAction:(id)sender;
- (BOOL)canExecute;
- (BOOL)canDetachActionAsWindow;
- (void)dispose;

@property BOOL isProcessing;
@property (nonatomic) BOOL allowDetach;
@property (nonatomic) BOOL allowLock;
@property BOOL keepActionDisplayed;
@property BOOL showPrevActionEnabled;
@property BOOL showNextActionEnabled;
@property BOOL indexMatchesPartnerIndex;
@property (copy) NSString *actionPositionString;
@property (readonly) MGSTaskSpecifierManager *actionController;
@property (nonatomic) BOOL taskResultDisplayLocked;
@property (nonatomic) NSInteger selectedPartnerIndex;
@property (readonly) NSInteger selectedIndex;

//@property (readonly) MGSScript *script;
@property (strong, nonatomic) MGSTaskSpecifier *action;
@property (readonly) MGSActionViewController *actionViewController;

//@property (readonly) NSView *view;
@property (unsafe_unretained) id delegate;
- (IBAction)executeScript:(id)sender;
- (IBAction)detachActionAsWindow:(id)sender;
- (void)actionInputModified;
- (IBAction)syncPartnerSelectedIndex:(id)sender;
-(void)syncToPartnerSelectedIndex;
@end
