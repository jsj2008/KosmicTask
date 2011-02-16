-- untitled.applescript
-- cocoa-applescript test

-- Created by Jonathan on 17/04/2010.
-- Copyright 2010 mugginsoft.com. All rights reserved.

-- see
-- https://secure.macscripter.net/viewtopic.php?id=30313
property NSMutableArray : class "NSMutableArray"

script KosmicTask
	
	on run
		say "run"
	end run
	
	on execute_(_inputs)
		
		display dialog "here"
		tell class "NSString" of current application
			set newText to its |stringWithFormat_|("%@", "BYE")
		end tell
		
		tell class "NSURL" of current application
			set myurl to URLWithString_("www.mugginsoft.com")
		end tell
		
		tell class "NSURLRequest" of current application
			set myurlobj to requestWithURL_(myurl)
		end tell
		
		set theDataSource to NSMutableArray's alloc()'s init()
		
		set NSWebView to class "WebView" of current application
		
		
		set ABAddressBook to class "ABAddressBook" of current application
		set myAddressBook to ABAddressBook's addressBook
		set people to myAddressBook's people
		display dialog (count of people)
		
		
		
		set frameRect to {origin:{x:0, y:0}, size:{width:1000, height:1000}}
		set mywebView to NSWebView's alloc()'s initWithFrame_frameName_groupName_(frameRect, "frame", "group")
		
		say newText as string
		(*
		set NSAppleScript to class "NSAppleScript" of current application
		script cocoa_applescript_testAppDelegate
			property parent : class "NSObject"
		end script
		set myAppleScript to NSAppleScript's alloc()'s initWithSource_(mySource)

		*)
		return newText
	end execute_
	
end script
