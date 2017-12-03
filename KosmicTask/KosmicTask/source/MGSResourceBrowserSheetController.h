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
@class MGSScript;

enum {
    kMGSResourceBrowserSheetReturnCancel,
    kMGSResourceBrowserSheetReturnCopy,
    kMGSResourceBrowserSheetReturnInsert,
    kMGSResourceBrowserSheetReturnShowCodeAssistant,
    kMGSResourceBrowserSheetReturnShowFile,
};
typedef NSInteger MGSResourceBrowserSheetReturnValue;

@interface MGSResourceBrowserSheetController : NSWindowController {
	MGSResourceBrowserViewController *resourceBrowserViewController;
	IBOutlet NSView *templateView;
	IBOutlet NSButton *okButton;
    IBOutlet NSButton *copyButton;
	NSString *resourceText;
    MGSScript *__weak script;
	BOOL resourcesChanged;

}

@property (readonly) MGSResourceBrowserViewController *resourceBrowserViewController;
@property (readonly, copy) NSString *resourceText;
@property BOOL resourcesChanged;
@property (weak, nonatomic) MGSScript *script;

- (IBAction)cancel:(id)sender;
- (IBAction)copyToPasteboardAction:(id)sender;
- (IBAction)insertTemplateAction:(id)sender;
- (IBAction)openCodeAssistantAction:(id)sender;
- (IBAction)openFile:(id)sender;

- (MGSLanguagePropertyManager *)languagePropertyManager;
@end
