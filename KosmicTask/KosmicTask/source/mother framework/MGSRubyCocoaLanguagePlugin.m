//
//  MGSRubyCocoaLanguagePlugin.m
//  KosmicTask
//
//  Created by Jonathan on 28/04/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSRubyCocoaLanguagePlugin.h"
#import "MGSRubyCocoaLanguage.h"

@implementation MGSRubyCocoaLanguagePlugin

/*
 
 - languageClass
 
 */
- (Class)languageClass
{
	return [MGSRubyCocoaLanguage class];
}

@end
