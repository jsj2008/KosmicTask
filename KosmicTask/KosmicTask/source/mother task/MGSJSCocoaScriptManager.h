//
//  MGSJSCocoaScriptManager.h
//  KosmicTask
//
//  Created by Jonathan on 10/12/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSScriptExecutorManager.h"

@class JSCocoa;

@interface MGSJSCocoaScriptManager : MGSScriptExecutorManager {
	JSCocoa* jsCocoa;
}

@end
