//
//  MGSKshScriptRunner.m
//  KosmicTask
//
//  Created by Jonathan on 30/04/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSKshScriptRunner.h"
#import "MGSKshLanguage.h"

@implementation MGSKshScriptRunner

/*
 
 - languageClass
 
 */
- (Class)languageClass
{
	return [MGSKshLanguage class];
}

@end
