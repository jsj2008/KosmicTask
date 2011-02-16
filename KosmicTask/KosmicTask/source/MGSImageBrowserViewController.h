//
//  MGSImageBrowserViewController.h
//  Mother
//
//  Created by Jonathan on 30/08/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

#import "MGSViewDelegateProtocol.h"

@interface MGSSaveImageSelectionAccessoryViewController : NSViewController <NSOpenSavePanelDelegate, MGSViewDelegateProtocol> {
	NSString *_fileCountString;
	NSInteger _fileCount;
	NSInteger _overwriteOption;
	BOOL _openInDefaultAppAfterSave;
}
@property (copy) NSString *fileCountString;
@property NSInteger fileCount;
@property BOOL openInDefaultAppAfterSave;
@property NSInteger overwriteOption;

@end

@class MGSNetAttachments;
@class PlacardScrollView;
@class MGSImageBrowserView;

@interface MGSImageBrowserViewController : NSViewController <NSOpenSavePanelDelegate> {
	IBOutlet PlacardScrollView *scrollView;
	NSMutableArray *_images;
	IBOutlet MGSImageBrowserView *_imageBrowser;
	MGSNetAttachments *_attachments;
	IBOutlet NSSlider *_slider;
	IBOutlet NSTextField *fileCountTextField;
	IBOutlet NSButton *_save;
	IBOutlet NSButton *_quicklook;
	NSString *_fileCountString;
	IBOutlet MGSSaveImageSelectionAccessoryViewController *_accessoryViewController;
	NSMenu *_menu;
	IBOutlet NSView *_splitViewAdditionalView;
}
@property MGSNetAttachments *attachments;
@property (readonly) NSString *fileCountString;
@property (readonly) MGSImageBrowserView *imageBrowser;
@property (assign) NSMenu *menu;
@property (readonly) NSView *splitViewAdditionalView;

- (IBAction)zoomChange:(id)sender;
- (void)reloadData;
- (IBAction)saveSelection:(id)sender;
- (IBAction)quicklook:(id)sender;
- (IBAction)save:(id)sender;

- (NSWindow *)window;
- (int) numberOfItemsInImageBrowser:(IKImageBrowserView *) browser;

@end
