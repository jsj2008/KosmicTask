//
//  MGSCshScriptRunner.m
//  KosmicTask
//
//  Created by Jonathan on 30/04/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSCshScriptRunner.h"
#import "MGSCshLanguage.h"

@implementation MGSCshScriptRunner

/*
 
 - languageClass
 
 */
- (Class)languageClass
{
	return [MGSCshLanguage class];
}

@end
