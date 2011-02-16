//
//  MGSShellScriptRunner.h
//  KosmicTask
//
//  Created by Jonathan on 29/04/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSScriptRunner.h"

@interface MGSExternalScriptRunner : MGSScriptRunner {
	NSData *stderrData;
}

@property (copy) NSData *stderrData;

- (NSString *)staticAnalyserPath;
- (NSString *)scriptFileNameForShell:(NSString *)scriptFileName;

@end
