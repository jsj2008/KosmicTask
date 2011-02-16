//
//  MGSPerlLanguagePlugIn.m
//  KosmicTask
//
//  Created by Jonathan on 30/04/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSPerlLanguagePlugIn.h"
#import "MGSPerlLanguage.h"

@implementation MGSPerlLanguagePlugIn

/*
 
 - languageClass
 
 */
- (Class)languageClass
{
	return [MGSPerlLanguage class];
}

@end
