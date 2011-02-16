//
//  MGSCshLanguagePlugin.m
//  KosmicTask
//
//  Created by Jonathan on 30/04/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSCshLanguagePlugin.h"
#import "MGSCshLanguage.h"

@implementation MGSCshLanguagePlugin

/*
 
 - languageClass
 
 */
- (Class)languageClass
{
	return [MGSCshLanguage class];
}

@end
