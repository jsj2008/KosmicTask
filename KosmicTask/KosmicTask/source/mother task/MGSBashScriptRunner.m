//
//  MGSBashScriptRunner.m
//  KosmicTask
//
//  Created by Jonathan on 30/04/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSBashScriptRunner.h"
#import "MGSBashLanguage.h"

@implementation MGSBashScriptRunner

/*
 
 - languageClass
 
 */
- (Class)languageClass
{
	return [MGSBashLanguage class];
}

@end
