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
	IBOutlet NSView *pluginView;
	MGSParameterPluginViewController *_parameterPluginViewController;
	IBOutlet NSButton *resetButton;
	BOOL _resetEnabled;
	id delegate;
	IBOutlet NSTextField *label;
}
@property NSView *pluginView;
@property MGSParameterPluginViewController *parameterPluginViewController;
@property (readonly) BOOL resetEnabled;
@property id delegate;

- (IBAction)resetToDefaultValue:(id)sender;

@end
