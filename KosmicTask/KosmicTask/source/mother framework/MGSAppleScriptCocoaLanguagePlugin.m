//
//  MGSAppleScriptCocoaLanguagePlugin.m
//  KosmicTask
//
//  Created by Jonathan on 26/04/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSAppleScriptCocoaLanguagePlugin.h"
#import "MGSAppleScriptCocoaLanguage.h"

@implementation MGSAppleScriptCocoaLanguagePlugin

/*
 
 - languageClass
 
 */
- (Class)languageClass
{
	return [MGSAppleScriptCocoaLanguage class];
}

@end
