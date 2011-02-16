//
//  MGSPythonScriptRunner.h
//  KosmicTask
//
//  Created by Jonathan on 29/04/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSExternalScriptRunner.h"

#define ENV_PYTHON_PATH @"PYTHONPATH"

@interface MGSPythonScriptRunner : MGSExternalScriptRunner {

}
- (NSString *)appscriptPath;
@end
