//
//  MGSPythonLanguagePlugin.m
//  KosmicTask
//
//  Created by Jonathan on 28/04/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSPythonLanguagePlugin.h"
#import "MGSPythonLanguage.h"

@implementation MGSPythonLanguagePlugin

/*
 
 - languageClass
 
 */
- (Class)languageClass
{
	return [MGSPythonLanguage class];
}

@end
