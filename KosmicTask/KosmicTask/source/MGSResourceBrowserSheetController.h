//
//  MGSResourceBrowserSheetController.h
//  KosmicTask
//
//  Created by Jonathan on 12/06/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSResourceBrowserViewController.h"

@class MGSLanguagePropertyManager;

@interface MGSResourceBrowserSheetController : NSWindowController {
	MGSResourceBrowserViewController *resourceBrowserViewController;
	IBOutlet NSView *templateView;
	IBOutlet NSButton *okButton;
	NSString *resourceText;
	NSString *scriptType;
	BOOL resourcesChanged;
	MGSLanguagePropertyManager *languagePropertyManager;
}

@property (readonly) MGSResourceBrowserViewController *resourceBrowserViewController;
@property (readonly, copy) NSString *resourceText;
@property (copy) NSString *scriptType;
@property BOOL resourcesChanged;
@property (copy, readonly) MGSLanguagePropertyManager *languagePropertyManager;

- (IBAction)ok:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)openFile:(id)sender;

@end
