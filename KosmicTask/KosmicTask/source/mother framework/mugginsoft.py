import yaml

class KosmicTaskController:

	# 
	# objectToString
	# 
	@classmethod
	def objectToString(self, resultObject):
    			
    	# get resultObject as YAML string
		result = yaml.dump(resultObject)
		
		if result.startswith("---") == False:
			result = "---\n" + result
		
		return result
	
	#	 
	# printObject
	# 
	@classmethod
	def printObject(self, resultObject):
		
		result = self.objectToString(resultObject)
		
		print result
