//
//  MGSScalaLanguagePlugin.m
//  KosmicTask
//
//  Created by Jonathan on 07/08/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSScalaLanguagePlugin.h"


@implementation MGSScalaLanguagePlugin

/*
 
 - taskType
 
 */
- (NSString *)scriptType
{
	return @"Scala";
}

/*
 
 - displayName
 
 */
- (NSString *)displayName {
	return @"Scala";
}

/*
 
 - syntaxDefinition
 
 */
- (NSString *)syntaxDefinition
{
	/*
	 
	 To enable syntax highlighting this must return
	 the name of an existing Fragaria syntax definition name
	 
	 */
	return @"Scala";
}

/*
 
 - taskRunnerClassName
 
 */
- (NSString *)taskRunnerClassName
{
	return @"MGSScalaRunner";
}


/*
 
 - taskRunnerProcessName
 
 */
- (NSString *)taskRunnerProcessName
{
	return @"KosmicTaskScalaRunner";
}
/*
 
 - canIgnoreBuildWarnings
 
 */
- (BOOL)canIgnoreBuildWarnings
{
	return NO;
}

/*
 
 - buildResultFlags
 
 */
- (MGSBuildResultFlags)buildResultFlags
{
	return kMGSCompiledScript;
}

@end
