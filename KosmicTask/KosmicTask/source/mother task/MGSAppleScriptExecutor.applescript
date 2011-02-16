-- MGSAppleScriptExecutor.applescript
-- KosmicTask

-- Created by Jonathan on 15/05/2010.
-- Copyright 2010 mugginsoft.com. All rights reserved.

script MGSAppleScriptExecutor
	
	property parent : class "NSObject"
	property p_maxArgs : 10
	property p_funcName : "kosmictask"
	property scriptObject : missing value
	property resultObject : missing value
	property scriptError : missing value
	
	--
	-- loadModuleAtPath_functionName_arguments_
	-- 
	on loadModuleAtPath_className_functionName_arguments_(path_, klass_, func_, args_)
		set resultObject to ""
		try
			-- logging will output on stderr and be redirected back to the app
			--log path_
			
			-- have to coerce to string here else we get
			-- Can’t make «class ocid» id «data kptr30332200» into type «class psxf».
			-- The stuff returned from ObjC calls all comes back in a special class (<ocid>), 
			-- and you usually can't use them directly.
			set thePath to path_ as string
			set theFunc to func_ as string
			set theArgs to args_ as list
			
			-- load the script
			set theScript to load script (thePath as POSIX file)
			
			-- load script is meant to work in conjunction with save script.
			-- save script normally strips off the outer script x .. end script definition.
			-- we have saved our script directly so the script object may be present.
			try
				set scriptObject to kosmictask of theScript
				if class of scriptObject is not script then
					set scriptObject to missing value
				end if
			end try
			
			if scriptObject is missing value then
				set scriptObject to theScript
			end if
			
			-- evaluate script function
			--
			-- less than ideal but it is all that seems to work
			--
			if true then
				set argCount to count of theArgs
				
				-- validate function name
				if theFunc is not p_funcName then
					set scriptError to "Invalid handler name; handler name must be " & p_funcName
					return resultObject
				end if
				
				-- validate arg count
				if argCount > p_maxArgs then
					set scriptError to "Max parameter count of " & p_maxArgs & " exceeded "
					return resultObject
				end if
				
				-- note that if kosmictask handler does not exist in the
				-- script NO error is generated
				tell scriptObject
					if argCount = 0 then
						set resultObject to kosmictask()
					else if argCount = 1 then
						set resultObject to kosmictask(item 1 of theArgs)
					else if argCount = 2 then
						set resultObject to kosmictask(item 1 of theArgs, item 2 of theArgs)
					else if argCount = 3 then
						set resultObject to kosmictask(item 1 of theArgs, item 2 of theArgs, item 3 of theArgs)
					else if argCount = 4 then
						set resultObject to kosmictask(item 1 of theArgs, item 2 of theArgs, item 3 of theArgs, item 4 of theArgs)
					else if argCount = 5 then
						set resultObject to kosmictask(item 1 of theArgs, item 2 of theArgs, item 3 of theArgs, item 4 of theArgs, item 5 of theArgs)
					else if argCount = 6 then
						set resultObject to kosmictask(item 1 of theArgs, item 2 of theArgs, item 3 of theArgs, item 4 of theArgs, item 5 of theArgs, item 6 of theArgs)
					else if argCount = 7 then
						set resultObject to kosmictask(item 1 of theArgs, item 2 of theArgs, item 3 of theArgs, item 4 of theArgs, item 5 of theArgs, item 6 of theArgs, item 7 of theArgs, item 8 of theArgs)
					else if argCount = 8 then
						set resultObject to kosmictask(item 1 of theArgs, item 2 of theArgs, item 3 of theArgs, item 4 of theArgs, item 5 of theArgs, item 6 of theArgs, item 7 of theArgs, item 8 of theArgs, item 9 of theArgs)
					else if argCount = 9 then
						set resultObject to kosmictask(item 1 of theArgs, item 2 of theArgs, item 3 of theArgs, item 4 of theArgs, item 5 of theArgs, item 6 of theArgs, item 7 of theArgs, item 8 of theArgs, item 9 of theArgs, item 10 of theArgs)
					else if argCount = 10 then
						set resultObject to kosmictask(item 1 of theArgs, item 2 of theArgs, item 3 of theArgs, item 4 of theArgs, item 5 of theArgs, item 6 of theArgs, item 7 of theArgs, item 8 of theArgs, item 9 of theArgs, item 10 of theArgs)
					else
						set scriptError to "Invalid handler parameter count"
						return resultObject
					end if
				end tell
				
			else
				set resultObject to evaluateScriptFunction(scriptObject, theFunc, theArgs)
			end if
			
		on error errorMessage
			log "error = " & errorMessage
			set scriptError to errorMessage
		end try
		
		return me
		
	end loadModuleAtPath_className_functionName_arguments_
	
	--
	-- evaluateScriptFunction
	-- 
	-- this works in regular AS but fails here.
	-- passing any script as a parameter to run scripts fails,
	-- presumably because another AS component is instantiated and that component
	-- cannot handle the ASObjC scipt.
	on evaluateScriptFunction(theScript, theFunc, theArgs)
		
		set i to 1
		set expr to "on run {x} " & linefeed
		set expr to expr & "tell x " & linefeed
		set expr to expr & "return " & theFunc & "("
		repeat (count of theArgs) times
			if i = 2 then
				set expr to expr & ", "
			end if
			set expr to expr & "item " & i & " of theArgs "
		end repeat
		set expr to expr & ")" & linefeed
		set expr to expr & "end tell" & linefeed
		set expr to expr & "end" & linefeed
		
		log expr
		return run script expr with parameters {theScript}
	end evaluateScriptFunction
	
end script
