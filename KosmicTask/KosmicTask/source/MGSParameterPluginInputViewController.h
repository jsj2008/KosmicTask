//
//  MGSParameterPluginInputViewController.h
//  Mother
//
//  Created by Jonathan on 02/07/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "MGSParameterPluginViewController.h"

@interface MGSParameterPluginInputViewController : NSViewController <MGSParameterPluginViewControllerDelegate> {
	IBOutlet NSView *__weak pluginView;
	MGSParameterPluginViewController *__weak _parameterPluginViewController;
	IBOutlet NSButton *resetButton;
	BOOL _resetEnabled;
	id __unsafe_unretained delegate;
	IBOutlet NSTextField *label;
}
@property (weak) NSView *pluginView;
@property (weak) MGSParameterPluginViewController *parameterPluginViewController;
@property (readonly) BOOL resetEnabled;
@property (unsafe_unretained) id delegate;

- (IBAction)resetToDefaultValue:(id)sender;

@end
