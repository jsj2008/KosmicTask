//
//  MGSActionParameterEditViewController.h
//  Mother
//
//  Created by Jonathan on 03/03/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MGSTaskSpecifier;
@class MGSParameterViewManager;
@class MGSScriptParameterManager;
@class MGSEmptyParameterViewController;
@class MGSParameterSplitView;

@interface MGSActionParameterEditViewController : NSViewController {
	
	IBOutlet NSTextField *inputCountText;						// number of inputs
	IBOutlet NSSegmentedControl *inputSegmentedControl;			// input segment control
	IBOutlet MGSParameterViewManager *parameterViewManager;		// parameter view handler
	IBOutlet MGSEmptyParameterViewController *emptyParameterViewController;	// view to be displayed when zero parameters are defined
	IBOutlet NSView *parameterView;								// view containing parameters
	IBOutlet NSScrollView *parameterScrollView;					// parameter scrollview
	
	IBOutlet NSButton *_copyHandlerTemplateButton;				// copy handler template button
	
	MGSTaskSpecifier *_action;
	MGSScriptParameterManager *_parameterHandler;
	
	NSInteger _inputCount;
}
@property NSInteger inputCount;
@property MGSTaskSpecifier *action;
@property NSView *parameterView;

- (IBAction)segmentClick:(id)sender;
- (IBAction)copyHandlerTemplate:(id)sender;

- (NSString *)subroutineName;
- (void)setSubroutineName:(NSString *)name;
@end
