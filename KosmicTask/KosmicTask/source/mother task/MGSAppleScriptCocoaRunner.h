//
//  MGSAppleScriptCocoaRunner.h
//  KosmicTask
//
//  Created by Jonathan on 27/04/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSExternalScriptRunner.h"

@interface MGSAppleScriptCocoaRunner : MGSExternalScriptRunner {
	NSString *outputFilePath;
}

@end
