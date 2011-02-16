//
//  MGSJavaLanguagePlugin.m
//  KosmicTask
//
//  Created by Jonathan on 01/08/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSJavaLanguagePlugin.h"
#import "MGSJavaLanguage.h"

@implementation MGSJavaLanguagePlugin

/*
 
 - languageClass
 
 */
- (Class)languageClass
{
	return [MGSJavaLanguage class];
}

@end
