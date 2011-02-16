//
//  MGSZshScriptRunner.m
//  KosmicTask
//
//  Created by Jonathan on 30/04/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSZshScriptRunner.h"
#import "MGSZshLanguage.h"

@implementation MGSZshScriptRunner

/*
 
 - languageClass
 
 */
- (Class)languageClass
{
	return [MGSZshLanguage class];
}

/*
 
 - build
 
 zsh has no syntax check option
 
 */
- (BOOL) build
{
	return YES;
}	

@end
