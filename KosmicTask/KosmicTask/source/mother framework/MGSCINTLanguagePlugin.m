//
//  MGSCINTLanguagePlugin.m
//  KosmicTask
//
//  Created by Jonathan on 07/08/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSCINTLanguagePlugin.h"
#import "MGSCINTLanguage.h"

@implementation MGSCINTLanguagePlugin

/*
 
 - languageClass
 
 */
- (Class)languageClass
{
	return [MGSCINTLanguage class];
}

@end
