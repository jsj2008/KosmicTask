//
//  MGSPythonObjCLanguagePlugin.m
//  KosmicTask
//
//  Created by Jonathan on 30/04/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSPythonObjCLanguagePlugin.h"
#import "MGSPythonObjCLanguage.h"

@implementation MGSPythonObjCLanguagePlugin

/*
 
 - languageClass
 
 */
- (Class)languageClass
{
	return [MGSPythonObjCLanguage class];
}

@end
