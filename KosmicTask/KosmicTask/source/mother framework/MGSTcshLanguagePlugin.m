//
//  MGSTcshLanguagePlugin.m
//  KosmicTask
//
//  Created by Jonathan on 30/04/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSTcshLanguagePlugin.h"
#import "MGSTcshLanguage.h"

@implementation MGSTcshLanguagePlugin

/*
 
 - languageClass
 
 */
- (Class)languageClass
{
	return [MGSTcshLanguage class];
}

@end
