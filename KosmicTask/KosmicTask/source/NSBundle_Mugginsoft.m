//
//  NSBundle_Mugginsoft.m
//  Mother
//
//  Created by Jonathan on 28/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "NSBundle_Mugginsoft.h"


@implementation NSBundle (Mugginsoft)


/*
 
 bundle info.plist object for key
 
 */
+(id) mainBundleInfoObjectForKey:(NSString *)key
{
	NSDictionary *info = [[self mainBundle] localizedInfoDictionary];
	id object = [info objectForKey:key];
    if (object) {
        return object;
	}
	
	info = [[self mainBundle] infoDictionary];
    return [info objectForKey:key];
}

/*
 
 path for custom auxiliary executable
 
 */
- (NSString *)pathForCustomAuxiliaryExecutable:(NSString *)execName
{
	// path to agent/daemon executable
	// NOTE:
	// Placing KosmicTaskServer in pathForAuxiliaryExecutable (which is just in /contents/MACOS) causes a curious problem.
	// When an AppleScript is run the componentInstance contacts the windowServer and if it is being run from
	// the bundle's /contents/MACOS it shows a dock icon for it!
	// Moving the executable to the resource folder solves the problem.
	// However code signing doesn't like executables in the resources folder.
	// Creating a further an Auxiliary sub folder in /Contents/MacOs seems to work.
	// BUT, executables in Auxiliary sub folder cannot find path to shared framework!
	// shared support path seems to work.
	// except cannot seem to allow user interaction
	/*
	NSString *path = [[self executablePath] stringByDeletingLastPathComponent];
	path = [path stringByAppendingPathComponent:@"Auxiliary"];
	path = [path stringByAppendingPathComponent:execName];
	*/
	
	//NSString *path = [self sharedSupportPath];
	//NSString *path = [self executablePath];
	//path = [path stringByAppendingPathComponent:execName];
	
	NSString *path = [self pathForAuxiliaryExecutable:execName];
	return path;
}


@end
