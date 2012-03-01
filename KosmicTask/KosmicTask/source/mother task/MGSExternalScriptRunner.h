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
    BOOL captureStdErr;
}

@property (copy) NSData *stderrData;
@property BOOL captureStdErr;

- (NSString *)staticAnalyserPath;
- (NSString *)scriptFileNameForShell:(NSString *)scriptFileName;

@end
