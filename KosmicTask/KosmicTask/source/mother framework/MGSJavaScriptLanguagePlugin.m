//
//  MGSJavaScriptLanguagePlugin.m
//  KosmicTask
//
//  Created by Jonathan on 01/08/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSJavaScriptLanguagePlugin.h"
#import "MGSJavaScriptLanguage.h"

@implementation MGSJavaScriptLanguagePlugin

/*
 
 - languageClass
 
 */
- (Class)languageClass
{
	return [MGSJavaScriptLanguage class];
}

@end
