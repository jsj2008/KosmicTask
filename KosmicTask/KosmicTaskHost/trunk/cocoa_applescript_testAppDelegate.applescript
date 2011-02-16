--
--  cocoa_applescript_testAppDelegate.applescript
--  cocoa-applescript test
--
--  Created by Jonathan on 17/04/2010.
--  Copyright 2010 mugginsoft.com. All rights reserved.
--

script cocoa_applescript_testAppDelegate
	property parent : class "NSObject"
	property KosmicTask : missing value
	property inputs : missing value
	property Outputs : missing value
	
	(*
	
	applicationWillFinishLaunching_
	
	*)
	on applicationWillFinishLaunching_(aNotification)
		
		processTask()
		
	end applicationWillFinishLaunching_
	
	(*
	
	processTask
	
	*)
	on processTask()
		-- get the inputs
		
		tell KosmicTask to run
		
		-- execute the task with inputs
		tell KosmicTask
			set Outputs to run
		end tell
		
		
		-- return the outputs
		
		-- now quit
		tell current application to quit
		
	end processTask
	
end script