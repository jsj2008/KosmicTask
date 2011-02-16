//
//  MGSF-ScriptLanguagePlugin.m
//  KosmicTask
//
//  Created by Jonathan on 31/07/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSF-ScriptLanguagePlugin.h"
#import "MGSF_ScriptLanguage.h"

@implementation MGSF_ScriptLanguagePlugin

/*
 
 - languageClass
 
 */
- (Class)languageClass
{
	return [MGSF_ScriptLanguage class];
}

@end
