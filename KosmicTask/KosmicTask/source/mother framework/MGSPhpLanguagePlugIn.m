//
//  MGSPhpLanguagePlugIn.m
//  KosmicTask
//
//  Created by Jonathan on 30/04/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSPhpLanguagePlugIn.h"
#import "MGSPhpLanguage.h"

@implementation MGSPhpLanguagePlugIn

/*
 
 - languageClass
 
 */
- (Class)languageClass
{
	return [MGSPhpLanguage class];
}


@end
