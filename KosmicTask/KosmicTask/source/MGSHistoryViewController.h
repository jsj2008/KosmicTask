//
//  MGSHistoryViewController.h
//  Mother
//
//  Created by Jonathan on 14/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MGSTaskSpecifierManager;
@class MGSHistoryViewController;
@class MGSTaskSpecifier;
@class MGSNetClient;
@class AMProgressIndicatorTableColumnController;

@protocol MGSHistoryViewController
@required
- (void)history:(MGSHistoryViewController *)aHistory actionSelected:(MGSTaskSpecifier *)action;
- (void)historyExecuteSelectedAction:(MGSHistoryViewController *)history;
@end

@interface MGSHistoryViewController : NSViewController {
	IBOutlet NSTableView *historyTable;
	id __unsafe_unretained _delegate;
	MGSTaskSpecifierManager *__weak _actionHistory;
	NSInteger _maxHistoryCount;
	//AMProgressIndicatorTableColumnController *_progressColumnController;
	MGSTaskSpecifier *_delegatedAction;
	BOOL _ignoreTableSelectionChange;
}

@property (unsafe_unretained) id delegate;
@property (weak) IBOutlet MGSTaskSpecifierManager *actionHistory;
@property NSInteger maxHistoryCount;

- (void)loadSavedHistory;
- (void)saveHistory;
- (IBAction)clearHistory:(id)sender;
- (IBAction)setHistoryCapacity:(id)sender;
- (CGFloat)minViewHeight;

@end
