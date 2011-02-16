//
//  MGSRubyScriptRunner.h
//  KosmicTask
//
//  Created by Jonathan on 30/04/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSExternalScriptRunner.h"

#define ENV_RUBY_LIB @"RUBYLIB"

@interface MGSRubyScriptRunner : MGSExternalScriptRunner {

}
- (NSString *)appscriptPath;

@end
