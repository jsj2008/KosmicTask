//
//  MGSTcshScriptRunner.m
//  KosmicTask
//
//  Created by Jonathan on 30/04/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSTcshScriptRunner.h"
#import "MGSTcshLanguage.h"

@implementation MGSTcshScriptRunner

/*
 
 - languageClass
 
 */
- (Class)languageClass
{
	return [MGSTcshLanguage class];
}

/*
 
 - build
 
 tcsh has no syntax check option
 
 */
- (BOOL) build
{
	return YES;
}	
@end
