//
//  MGSTclshLanguagePlugin.m
//  KosmicTask
//
//  Created by Jonathan on 30/04/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSTclshLanguagePlugin.h"
#import "MGSTclshLanguage.h"

@implementation MGSTclshLanguagePlugin

/*
 
 - languageClass
 
 */
- (Class)languageClass
{
	return [MGSTclshLanguage class];
}


@end
