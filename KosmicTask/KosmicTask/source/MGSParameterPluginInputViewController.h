//
//  MGSParameterPluginInputViewController.h
//  Mother
//
//  Created by Jonathan on 02/07/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MGSParameterSubViewController;

@interface MGSParameterPluginInputViewController : NSViewController {
	IBOutlet NSView *pluginView;
	MGSParameterSubViewController *_subViewController;
	IBOutlet NSButton *resetButton;
	BOOL _resetEnabled;
}
@property NSView *pluginView;
@property MGSParameterSubViewController *subViewController;
@property (readonly) BOOL resetEnabled;

- (IBAction)resetToDefaultValue:(id)sender;

@end
