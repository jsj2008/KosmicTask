//
//  MGSFolderPathParameterPlugin.m
//  KosmicTask
//
//  Created by Jonathan on 18/07/2011.
//  Copyright 2011 mugginsoft.com. All rights reserved.
//

#import "MGSFolderParameterPlugin.h"

#import "MGSFolderParameterEditViewController.h"
#import "MGSFolderParameterInputViewController.h"

NSString *MGSKeyFolderPath = @"FolderPath";

@implementation MGSFolderPathParameterPlugin

/*
 
 - editViewControllerClass
 
 */
- (id)editViewControllerClass
{
	return [MGSFolderParameterEditViewController class];
}


/*
 
 - inputViewControllerClass
 
 */
- (id)inputViewControllerClass
{
	return [MGSFolderParameterInputViewController class];
}

/* 
 
 menu item string
 
 */
- (NSString *)menuItemString
{
	return NSLocalizedString(@"Folder Path", @"Parameter plugin menu item string");
}

@end
