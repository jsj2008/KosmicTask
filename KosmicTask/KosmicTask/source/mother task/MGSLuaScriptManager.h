//
//  MGSLuaScriptManager.h
//  KosmicTask
//
//  Created by Jonathan on 08/12/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "MGSScriptExecutorManager.h"
#import <LuaCocoa/LuaCocoa.h>

@interface MGSLuaScriptManager : MGSScriptExecutorManager {

	LuaCocoa* lua_cocoa;
}

@end

