//
//  MGSLuaCocoaLanguagePlugin
//  KosmicTask
//
//  Created by Jonathan on 08/12/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSLuaCocoaLanguagePlugin.h"
#import "MGSLuaCocoaLanguage.h"

@implementation MGSLuaCocoaLanguagePlugin

/*
 
 - languageClass
 
 */
- (Class)languageClass
{
	return [MGSLuaCocoaLanguage class];
}

@end
