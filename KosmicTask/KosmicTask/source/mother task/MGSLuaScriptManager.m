//
//  MGSLuaScriptManager.m
//  KosmicTask
//
//  Created by Jonathan on 08/12/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSLuaScriptManager.h"


@interface MGSLuaScriptExecutor : NSObject < MGSScriptExecutor> {
}
@end

@implementation MGSLuaScriptManager


/*
 
 - setupEnvironment:
 
 */
- (BOOL) setupEnvironment:(MGSScriptRunner *)scriptRunner
{
	//int w = 1;
	//while(w);
	
	// get path to our lua entrypoint
	NSString *scriptPath = [[scriptRunner resourcesPath] stringByAppendingPathComponent:@"MGSLuaScriptExecutor.lua"];

	// establish connection
	lua_cocoa = [[LuaCocoa alloc] init];
	lua_State *lua_state = [lua_cocoa luaState];
	
	// load file
	int the_error = luaL_loadfile(lua_state, [scriptPath fileSystemRepresentation]);
	if (the_error) {
		self.error = [NSString stringWithFormat:@"LuaCocoa : %s", lua_tostring(lua_state, -1)];
		return NO;
	} 
	
	// call it
	the_error = lua_pcall(lua_state, 0, 0, 0);
	if(the_error)
	{
		self.error = [NSString stringWithFormat:@"LuaCocoa : %s", lua_tostring(lua_state, -1)];
		return NO;
	}
	
	return YES;
}

/*
 
 - executorClassName
 
 */
- (NSString *)executorClassName
{
	return @"MGSLuaScriptExecutor";
}

/*
 
 - executor
 
 */
- (id)executor
{
	id executor = [super executor];
	//NSAssert([executor respondsToSelector:@selector(setLuaCocoaState)], @"executor does not respond to setLuaCocoaState:");
	
	// docs say that setLuaCocoaState: must be set - not sure if this is the case
	// http://playcontrol.net/opensource/LuaCocoa/documentation.html
	//[executor setLuaCocoaState:[lua_cocoa luaState]];
	
	return executor;
}

@end

