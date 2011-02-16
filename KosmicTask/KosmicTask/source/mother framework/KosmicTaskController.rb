require "yaml"

class KosmicTaskController 

	# 
	# objectToString
	# 
	def self.objectToString(resultObject)
    			
    	# get resultObject as YAML string
		result = YAML::dump(resultObject)
		
		return result
	end
	
	#	 
	# printObject
	# 
	def self.printObject(resultObject)
		
		result = self.objectToString(resultObject)
		
    	puts result
	end
end