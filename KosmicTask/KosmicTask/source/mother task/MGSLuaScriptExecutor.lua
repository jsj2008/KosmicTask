--  MGSLuaScriptExecutor.lua
--  KosmicTask
--
-- Created by Jonathan on 08/12/2010.
-- Copyright 2010 mugginsoft.com. All rights reserved.
--
--
LuaCocoa.import("Foundation")

luaScriptExecutor = LuaCocoa.CreateClass("MGSLuaScriptExecutor", NSObject)


luaScriptExecutor["loadModuleAtPath_className_functionName_arguments_"] = 
{
	function (self, pathNSString, classNSString, functionNameNSString, argumentsNSArray)
		
		-- arguments are of type userdata
		local pathString = tostring(pathNSString)
		local functionNameString = tostring(functionNameNSString)
		
		-- script argument array needs to be global as loadString compiles
		-- into a global environment http://www.lua.org/pil/8.html
		globalKTargumentsArray = {}	
		
		-- see http://www.lua.org/pil/8.html
		-- load chunk containing our function
		local kosmicTaskChunk = loadfile(pathString)
		if kosmicTaskChunk == nil then
			return "Error loading Lua script. Please build to review errors."
		end
		
		-- run our chunk , afterwhich functionNameString() should be defined
		kosmicTaskChunk()
		
		-- build string to call function defined within kosmicTaskChunk.
		-- note that we cannot use ipairs(argumentsNSArray) as argumentsNSArray is type userdata
		local taskString = functionNameString .. "("
		local argCount = argumentsNSArray:count()
		if argCount > 0 then
			for i=1,argCount do
				table.insert(globalKTargumentsArray, tostring(argumentsNSArray[i]))
			end
			taskString = taskString .. "unpack(globalKTargumentsArray)"
		end
		taskString = "return " .. taskString .. ")"

		--
		local taskFunc = loadstring(taskString)
		if taskFunc == nil then
			return "Error loading Lua script invocation string."
		end
		
		--call our task function
		return taskFunc()
	end,
	"-@@:@@@@"
}