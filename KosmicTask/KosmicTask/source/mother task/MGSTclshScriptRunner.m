//
//  MGSTclshScriptRunner.m
//  KosmicTask
//
//  Created by Jonathan on 30/04/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSTclshScriptRunner.h"
#import "MGSTclshLanguage.h"

@implementation MGSTclshScriptRunner

/*
 
 - languageClass
 
 */
- (Class)languageClass
{
	return [MGSTclshLanguage class];
}

/*
 
 - build
 
 tclsh has no syntax check option
 
 */
- (BOOL) build
{
	return YES;
}	

/*
 
 - launchEnvironment
 
 http://staf.sourceforge.net/current/STAFTcl.htm
 
 To configure Tcl to find the STAF Tcl support files, you need to set or update your TCLLIBPATH environment variable so that it includes the STAF directory containing the Tcl support files.
 On Unix, add the <STAF Root>/lib directory to your TCLLIBPATH. For example:
 export TCLLIBPATH=/usr/local/staf/lib
 Or, if you already have set TCLLIBPATH to contain another directory (e.g. /usr/lib), then you would add the STAF lib directory and use a space to separate multiple directories. For example:
 export TCLLIBPATH="/usr/local/staf/lib /usr/lib"
 On Windows, add the <STAF Root>/bin directory to your TCLLIBPATH.  Note that UNIX style slashes ("/") must be used as the file separator on Windows as well. For example:
 set TCLLIBPATH=C:/STAF/bin
 Or, if you already have set TCLLIBPATH to contain another directory (e.g. C:/Tcl/bin), then you would add the STAF bin directory and use a space to separate multiple directories. For example:
 set TCLLIBPATH="C:/STAF/bin C:/Tcl/bin"
 Note that TCLLIBPATH must contain a Tcl list of directories, using a space to separate multiple directories (unlike the PATH environment variable which uses colons on Unix or semi-colons on Windows to separate multiple directories).
 
 */
- (NSMutableDictionary *)launchEnvironment
{
	// we need to quote to prevent whitespace in path from looking like another directory
	NSString *tclPath = [NSString stringWithFormat:@"\"%@\"", [self resourcesPath]];
	
	NSMutableDictionary *env = [super launchEnvironment];
	NSArray *paths = [NSArray arrayWithObjects:tclPath,
					  nil];
	[self updateEnvironment:env pathkey:@"TCLLIBPATH" paths:paths separator:@" "];
	
	return env;
}

@end
