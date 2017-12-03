//
//  MGSOutputRequestViewController.h
//  Mother
//
//  Created by Jonathan on 05/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSRequestProgress.h"
#import "MGSViewDelegateProtocol.h"

extern NSString *MGSRunStatusContext;

@class MGSResultController;
@class MGSResultViewController;
@class MGSPopupButton;
@class MGSActionActivityViewController;
@class MGSTaskSpecifierManager;
@class MGSTaskSpecifier;
@class MGSResult;
@class MGSGradientView;

@interface MGSOutputRequestViewController : NSViewController <MGSRequestProgressDelegate, MGSViewDelegateProtocol> {

	IBOutlet MGSGradientView *_controlStripView;
	IBOutlet NSTableView *_progressTable;
	IBOutlet NSPopUpButton *_resultActionPopup;
	IBOutlet NSView *resultView;
	IBOutlet NSSplitView *splitView;
	IBOutlet NSScrollView *resultScrollView;
	IBOutlet NSButton *showPrevResult;
	IBOutlet NSButton *showNextResult;
	IBOutlet NSTextField *positionTextField;
	IBOutlet NSTextField *resultTextField;
	IBOutlet NSSegmentedControl *viewModeSegmentedControl;
	IBOutlet NSButton *detachWindowButton;
	IBOutlet NSButton *syncResultButton;
	IBOutlet NSButton *taskResultLockButton;

	NSArrayController *_progressArrayController;
	NSMutableArray *_progressArray;
	MGSResultController *_resultController;
	MGSResultViewController *_resultViewController;
	MGSActionActivityViewController *_actionActivityViewController;
	NSInteger _progressTimeResolution;
	
	BOOL _resultsAvailableForAction;
	BOOL _taskResultDisplayLocked;
	
	BOOL _showPrevResultEnabled;
	BOOL _showNextResultEnabled;
	BOOL _indexMatchesPartnerIndex;
	NSInteger _selectedPartnerIndex;
	NSInteger _selectedIndex;
	
	NSString * _resultPositionString;
	
	id __unsafe_unretained _delegate;
	MGSTaskSpecifierManager *_actionController;
	MGSTaskSpecifier *_action;
	MGSRequestProgress *_suspendedProgress;
	MGSRequestProgress *_observedProgress;
}

//@property (readonly) NSView *view;
@property (unsafe_unretained) id delegate;
//@property (readonly) MGSResultController *resultController;
@property BOOL showPrevResultEnabled;
@property BOOL showNextResultEnabled;
@property (nonatomic) BOOL indexMatchesPartnerIndex;
@property (copy) NSString * resultPositionString;
@property (nonatomic) BOOL resultsAvailableForAction;
@property (strong, nonatomic) MGSTaskSpecifier *action;
@property (copy) NSMutableArray *progressArray;
@property (nonatomic) BOOL taskResultDisplayLocked;
@property (nonatomic) NSInteger selectedPartnerIndex;
@property (readonly)NSInteger selectedIndex;
@property (readonly)MGSResultViewController *resultViewController;

- (void)setRequestProgress:(eMGSRequestProgress)value;
- (void)setRequestProgress:(eMGSRequestProgress)value object:(id)object;
- (void)progressDisplay;

- (void)segmentClick:(NSInteger)selectedSegment;
- (void)addResult:(MGSResult *)result;
- (void)actionInputModified;
- (MGSRequestProgress *)progress;
- (BOOL)canDetachResultAsWindow;

- (IBAction)showPreviousResult:(id)sender;
- (IBAction)showNextResult:(id)sender;
- (NSString *)resultPositionString;
- (IBAction)detachResultAsWindow:(id)sender;
- (IBAction)segControlClicked:(id)sender;

- (IBAction)syncPartnerSelectedIndex:(id)sender;
- (void)syncToPartnerSelectedIndex;
- (void)addLogString:(NSString *)value;
- (NSString *)logString;
- (void)dispose;
@end
