//
//  MGSActionWindowController.h
//  Mother
//
//  Created by Jonathan on 03/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSToolbarController.h"
#import "MGSTaskExecuteWindowController.h"
#import "MGSMotherModes.h"

@class MGSTaskSpecifier;
@class MGSToolbarController;
@class MGSRequestViewController;
@class MGSActionWindowController;

@protocol MGSActionWindowDelegate

@optional
- (void)actionWindowWillClose:(MGSActionWindowController *)actionWindowController;

@required

//- (void)actionWindowSaveAction:(MGSTaskSpecifier *)action;
@end

@interface MGSActionWindowController : MGSTaskExecuteWindowController <MGSToolbarDelegate, NSWindowDelegate> {
	IBOutlet NSView *view;
	IBOutlet NSButton *pinButton;
	IBOutlet NSTextField *_status;
	IBOutlet NSView *_minimalView;
	NSSize _normalMinSize;
	NSSize _minimalMinSize;
	NSSize _previousSize;
	NSView *_initialView;
	NSPoint _topLeftPoint;
	NSUInteger _styleMask;
	NSRect _previousMinimalFrame;
	NSRect _previousNormalFrame;
	NSView *_contentView;
	eMGSMotherWindowSizeMode _sizeMode;
}

- (IBAction)viewMenuMiniViewSelected:(id)sender;
- (void)setAction:(MGSTaskSpecifier *)anAction;
- (void)setDelegate:(id <MGSActionWindowDelegate>) object;
- (IBAction)pinButtonClick:(id)sender;
@end
