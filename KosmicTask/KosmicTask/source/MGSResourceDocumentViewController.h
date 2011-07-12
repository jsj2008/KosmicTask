//
//  MGSResourceDocumentViewController.h
//  KosmicTask
//
//  Created by Jonathan on 10/07/2011.
//  Copyright 2011 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

typedef enum {
  kMGSResourceDocumentModeView = 0,
  kMGSResourceDocumentModeEdit = 1,
}  MGSResourceDocumentMode;

@class MGSResourceItem;
@class MGSFragaria;

@interface MGSResourceDocumentViewController : NSViewController {
	MGSFragaria *fragaria;	// fragaria instance
	IBOutlet NSTabView *documentTabView;
	IBOutlet NSPopUpButton *docType;
	IBOutlet WebView *webView;
	IBOutlet NSView *editorHostView;
	MGSResourceDocumentMode mode;
	BOOL editModeActive;
	MGSResourceItem *selectedResource;
	IBOutlet id delegate;
	BOOL documentEdited;
	IBOutlet NSObjectController *resourceController;
}

- (IBAction)docFormatAction:(id)sender;
- (IBAction)docModeAction:(id)sender;

@property MGSResourceDocumentMode mode;
@property BOOL editModeActive;
@property (assign) MGSResourceItem *selectedResource;
@property BOOL documentEdited;

@end
