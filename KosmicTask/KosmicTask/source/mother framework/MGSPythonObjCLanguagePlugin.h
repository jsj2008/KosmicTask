//
//  MGSPythonObjCLanguagePlugin.h
//  KosmicTask
//
//  Created by Jonathan on 30/04/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSLanguagePlugin.h"

// don't be tempted to subclass MGSLanguagePythonPlugin
// and compile it into the executable.
//
// if more than onde definition for a class exists in
// multiple bundles then it is uncertain which will be used.
// this can play havoc when searching the bundle etc.
//
@interface MGSPythonObjCLanguagePlugin : MGSLanguagePlugin {

}

@end
