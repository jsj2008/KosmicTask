//
//  MGSResultViewController.h
//  Mother
//
//  Created by Jonathan on 06/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OSAKit/OSAKit.h>
#import "MGSViewController.h"
#import "MGSMotherModes.h"

@protocol MGSResultViewDelegate <NSObject>
@required
- (IBAction)saveResult:(id)sender;
- (IBAction)quicklook:(id)sender;
- (IBAction)sendResult:(id)sender;
- (IBAction)viewMenuViewAsSelected:(id)sender;
@end

@class MGSResult;
@class MGSImageBrowserViewController;
@class MarkerLineNumberView;
@class MGSPopupButton;
@class MGSScriptViewController;

@interface MGSResultViewController : MGSViewController <NSOpenSavePanelDelegate, MGSResultViewDelegate> {

	BOOL _nibLoaded;
	NSImage *_titleImage;
	MGSResult *_result;
	NSTreeController *_treeController;
	NSDictionary *_resultDictionary;
	MGSImageBrowserViewController *_imageBrowserViewController;
	
	// result presentation
	NSArray *_resultTreeArray;
	NSAttributedString *_resultString;
	NSAttributedString * _resultScriptString;
	NSAttributedString *_resultLogString;
    
	IBOutlet NSTabView *_tabView;
	IBOutlet NSOutlineView *_outlineView;
	IBOutlet NSTextView *_textView;
    IBOutlet NSTextView *_logTextView;
	IBOutlet NSMenu *_resultMenu;
	IBOutlet NSMenu *_resultViewMenu;
	IBOutlet NSMenu *_sendMenu;
	IBOutlet NSView *_savePanelAccessoryView;
	IBOutlet NSPopUpButton *_saveFormatPopupButton;
	IBOutlet NSPopUpButton *_displayFormatPopupButton;
	IBOutlet NSView *_textViewDragThumb;
	IBOutlet MGSPopupButton *_actionGearPopupButton;
	IBOutlet NSTextField *_resultFooterContentTextField;
	IBOutlet NSButton *_viewModeImageButton;
	IBOutlet NSSegmentedControl *_viewModeSegmentedControl;
	
    IBOutlet NSScrollView *_scriptViewScrollView;
    IBOutlet NSView *_scriptView;
    MGSScriptViewController *_scriptViewController;
    
	NSView *_dragThumbView;
	eMGSMotherResultView _viewMode;
	
	BOOL _openFileAfterSave;
	MarkerLineNumberView *_lineNumberView;
}

- (id)initWithDelegate:(id)delegate;
- (IBAction)saveResult:(id)sender;
- (IBAction)quicklook:(id)sender;
- (IBAction)sendResult:(id)sender;
- (IBAction)viewMenuViewAsSelected:(id)sender;
- (eMGSMotherViewConfig)viewConfig;;

- (IBAction)saveResultFiles:(id)sender;
- (IBAction)detachResultAsWindow:(id)sender;
- (IBAction)toggleLineWrapping:(id)sender;

- (NSView *)viewControl;
- (NSView *)splitViewAdditionalView;
- (void)setViewModeImage:(NSImage *)image;
- (IBAction)showNextViewMode:(id)sender;
- (IBAction)showPrevViewMode:(id)sender;
- (NSAttributedString *)saveResultString;
- (NSTextView *)saveResultTextView;
- (void)addLogString:(NSString *)value;

//@property NSString *title;
@property (copy) NSImage *titleImage;
@property MGSResult *result;
@property (copy) NSDictionary *resultDictionary;
@property (copy) NSArray *resultTreeArray;
@property NSView *dragThumbView;
@property eMGSMotherResultView viewMode;
@property (assign) NSMenu *resultMenu;
@property (copy) NSAttributedString *resultString;
@property (copy) NSAttributedString *resultScriptString;
@property (copy) NSAttributedString *resultLogString;
@property BOOL openFileAfterSave;

@end
