//
//  MGSAppleScriptLanguagePlugin.m
//  KosmicTask
//
//  Created by Jonathan on 26/04/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSAppleScriptLanguagePlugin.h"
#import "MGSAppleScriptLanguage.h"

@implementation MGSAppleScriptLanguagePlugin

/*
 
 - languageClass
 
 */
- (Class)languageClass
{
	return [MGSAppleScriptLanguage class];
}

@end

