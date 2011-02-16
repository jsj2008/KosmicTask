//
//  MGSPythonObjCScriptRunner.m
//  KosmicTask
//
//  Created by Jonathan on 30/04/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSPythonObjCScriptRunner.h"
#import "MGSPythonScriptManager.h"
#import "MGSPythonObjCLanguage.h"
/*
 
 
http://www.friday.com/bbum/2007/10/27/pyobjc-20-pyobjc-in-leopard/

 
 note that PyObjC does not support GC hence this app
 must used RC 
 
 */

@implementation MGSPythonObjCScriptRunner

/*
 
 - languageClass
 
 */
- (Class)languageClass
{
	return [MGSPythonObjCLanguage class];
}


/*
 
 - execute
 
 */
- (BOOL) execute
{
	// setup the process environment
	NSString *resourcePath = [self resourcesPath];
	NSArray *pythonPathArray = [NSArray arrayWithObjects: resourcePath, [self appscriptPath], nil];
	setenv([ENV_PYTHON_PATH UTF8String], [[pythonPathArray componentsJoinedByString:@":"] UTF8String], 1);
	
	/*
	 
	 setup the Python environment
	 
	 we do not have to link against PyObjC (there is no framework)
	 instead we just import in python
	 
	 /system/library/frameworks/python.framework/versions/2.6/Extras/lib/python/PyObjC
	 	 
	 */

	return [self executeWithManager:[MGSPythonScriptManager sharedManager]];
}


@end


