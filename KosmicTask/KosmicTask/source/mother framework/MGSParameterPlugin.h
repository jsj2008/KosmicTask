//
//  MGSParameterPlugin.h
//  Mother
//
//  Created by Jonathan on 06/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSPlugin.h"
#import "MGSParameterSubEditViewController.h"
#import "MGSParameterSubInputViewController.h"

extern NSString *MGSParameterPluginDefaultClassName;

@class MGSParameterPluginViewController;

@protocol MGSParameterPlugin

@required


@optional
-(MGSParameterSubEditViewController *)createEditViewControllerWithDelegate:(id)aDelegate;
-(MGSParameterSubInputViewController *)createInputViewControllerWithDelegate:(id)aDelegate;

@end

@interface MGSParameterPlugin : MGSPlugin <MGSParameterPlugin> {

}

- (id)createViewController:(Class)controllerClass delegate:(id)delegate;
- (id)editViewControllerClass;
- (id)inputViewControllerClass;
@end
