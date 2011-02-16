#
#  main.py
#  AwesomeTextEditor
#
#  Created by Steven Degutis on 3/24/10.
#  Copyright (c) 2010 Big Nerd Ranch, Inc. All rights reserved.
#
# note that serious problems were encountered due to the fact that a Python 2.5.2 framework
# was installed in /Library/Frameworks. removing this resolved problem
# could not import Foundation
#
from Foundation import *
from AppKit import *

import imp
import sys
import objc	
		
class MGSPythonScriptExecutor(NSObject):
	error = None
	
	@classmethod
	def scriptError(self):
		return self.error
		
	@classmethod
	def loadModuleAtPath_className_functionName_arguments_(self, path, klass, func, args):
		f = open(path)
		try:
			
			# verbose logging of exceptions
			objc.setVerbose(1)	
		
			theResult = "no result available"
			realfunc = None
			taskObject = None
			
			# load code at path as a module
			modKosmic = imp.load_module('modKosmic', f, path, (".py", "r", imp.PY_SOURCE))
			
			# without the mod reference this fails.
			# also getattr(modKosmic, klass, None) has issues.
			try:
				taskObject = eval('modKosmic.' + klass + '.alloc().init()')
				
			# attribute error thrown if cannot instantiate
			except AttributeError as x:
				taskObject = None
			except:
				# raise again and let the outer block handle it
				raise
					
			# get function from object
			if taskObject is not None:
								
				# get function
				realfunc = getattr(taskObject, func, None)
			
			# get function from module
			if realfunc is None:
				# get function
				realfunc = getattr(modKosmic, func, None)
			
			# if we have a function then call it
			if realfunc is not None:
			
				# call the function with our arguments
				# we make a tuple from our list and then unpack it
				theResult = realfunc(*tuple(args))
			
			# cannot find function
			else:
				theResult = 'cannot find function: ' + func
				self.error = theResult
				
		except Exception as e:
		
			# exception args are a tuple
			args = e.args
			if len(args) > 0:
				theResult = 'error :' + e.args[0]
			else:
				theResult = 'unknown error'
			
			self.error = theResult
			
		except:
			theResult = 'an error has occurred in the script executor'
			self.error = theResult
		finally:
			f.close()
		
		return theResult

	def new(self):
		self = super(MGSPythonScriptExecutor, self).new()
		if self is None: 
			return None
		else:
			self.__init__()
		return self
	
	def __init__(self):
		return None
		
	def echo_(self, aString):
		return aString
