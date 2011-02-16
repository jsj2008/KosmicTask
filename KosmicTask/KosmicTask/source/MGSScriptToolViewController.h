//
//  MGSScriptToolViewController.h
//  Mother
//
//  Created by Jonathan on 01/03/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSToolViewController.h"


@interface MGSScriptToolViewController : MGSToolViewController {
	IBOutlet NSButton *compileButton;
	IBOutlet NSButton *runButton;
	IBOutlet NSButton *dictionaryButton;
	NSWindow *_window;
	MGSTaskSpecifier *_actionSpecifier; // currently active action
}
- (IBAction)compileScript:(id)sender;
- (IBAction)showDictionary:(id)sender;
- (void)initialiseForWindow:(NSWindow *)window;
- (IBAction)runScript:(id)sender;
-(void)setActionSpecifier:(MGSTaskSpecifier *)action;
@end
