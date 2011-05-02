//
//  MGSFileParameterPlugin.m
//  Mother
//
//  Created by Jonathan on 06/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSFileParameterPlugin.h"
#import "MGSFileParameterEditViewController.h"
#import "MGSFileParameterInputViewController.h"

#import "MGSFilePathParameterPlugin.h"

NSString *MGSKeyUseFileExtensions = @"UseFileExtensions";
NSString *MGSKeyFileExtensions = @"FileExtensions";
NSString *MGSKeyFilePath = @"FilePath";

@implementation MGSFileParameterPlugin

/*
 
 - editViewControllerClass
 
 */
- (id)editViewControllerClass
{
	return [MGSFileParameterEditViewController class];
}


/*
 
 - inputViewControllerClass
 
 */
- (id)inputViewControllerClass
{
	return [MGSFileParameterInputViewController class];
}

/* 
 
 menu item string
 
 */
- (NSString *)menuItemString
{
	return NSLocalizedString(@"File", @"Parameter plugin menu item string");
}

/*
 
 - plugins
 
 */
- (NSArray *)plugins
{
	/*
	 
	 This plugin should be the principal class for the plugin bundle.
	 A such the plugins method will be called to load any additional plugins 
	 from the bundle.
	 
	 Note that we instantiate the plugins rather than returning their class.
	 
	 */
	NSMutableArray *plugins = [NSMutableArray arrayWithCapacity:5];
	[plugins addObject:[[MGSFilePathParameterPlugin alloc] init]];
	
	return plugins;
}
@end
