//
//  MGSJavaScriptCocoaLanguagePlugin.m
//  KosmicTask
//
//  Created by Jonathan on 10/12/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSJavaScriptCocoaLanguagePlugin.h"
#import "MGSJSCocoaLanguage.h"

@implementation MGSJavaScriptCocoaLanguagePlugin


/*
 
 - languageClass
 
 */
- (Class)languageClass
{
	return [MGSJSCocoaLanguage class];
}

@end
