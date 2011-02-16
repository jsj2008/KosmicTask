#  MGSRubyScriptExecutor.rb
#  KosmicTask
#
#  Created by Jonathan on 14/05/2010.
#  Copyright 2010 mugginsoft.com. All rights reserved.
#
#
require 'osx/cocoa'

class MGSRubyScriptExecutor < OSX::NSObject
  include OSX

  @error = nil
  
  def scriptError()
	return @error
  end
  
  def loadModuleAtPath_className_functionName_arguments(path, klass, func, args)
  
	begin 
	
		# classnames are constant so must begin with a capital
		#klass = 'KosmicTask'
		
		# load the ruby
		require path
		
		# calling send directly requires an explicit argument list.
		# the only way around this seems to be to use eval.
		# the :identifies a literal symbol
		expr = "send :" + func 
		0.upto(args.length - 1) do |i| 
			expr << " , args[" << i.to_s << "]"
		end

		# try and instantiate class.
		# if this fails try and call module function
		# note tha Bus error occurs
		# if the taskObj expression cannot be evaluated
		# ie: either KosmicTask class does not exist or the function does not exist.
		begin
		
			# get instance of class
			taskObj = eval(klass).new
			
			# evaluate send on the taskObj
			expr = "taskObj." + expr 
		
		rescue => x
			# fallthrough to call module function
		
		end
		
		# evaluate our expression
		theResult = eval expr
	rescue => e
		# can use $! for last error
		@error = "error : " + e.message
		theResult = "error : " + e.message

	ensure
	end
	
	return theResult
  end
  
  def echo(obj)
	return obj
  end
end
