//
//  MGSLuaLanguagePlugin.m
//  KosmicTask
//
//  Created by Jonathan on 07/03/2011.
//  Copyright 2011 mugginsoft.com. All rights reserved.
//

#import "MGSLuaLanguagePlugin.h"
#import "MGSLuaLanguage.h"

@implementation MGSLuaLanguagePlugin

/*
 
 - languageClass
 
 */
- (Class)languageClass
{
	return [MGSLuaLanguage class];
}


@end
