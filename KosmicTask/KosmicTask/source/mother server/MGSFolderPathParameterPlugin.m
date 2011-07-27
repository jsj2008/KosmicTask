//
//  MGSFolderPathParameterPlugin.m
//  KosmicTask
//
//  Created by Jonathan on 18/07/2011.
//  Copyright 2011 mugginsoft.com. All rights reserved.
//

#import "MGSFolderPathParameterPlugin.h"

#import "MGSFolderPathParameterEditViewController.h"
#import "MGSFolderPathParameterInputViewController.h"

NSString *MGSKeyFolderPath = @"FolderPath";

@implementation MGSFolderPathParameterPlugin

/*
 
 - editViewControllerClass
 
 */
- (id)editViewControllerClass
{
	return [MGSFolderPathParameterEditViewController class];
}


/*
 
 - inputViewControllerClass
 
 */
- (id)inputViewControllerClass
{
	return [MGSFolderPathParameterInputViewController class];
}

/* 
 
 menu item string
 
 */
- (NSString *)menuItemString
{
	return NSLocalizedString(@"Folder Path", @"Parameter plugin menu item string");
}

@end
