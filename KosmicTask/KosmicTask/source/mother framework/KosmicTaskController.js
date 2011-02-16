/*
 
 JSON
 
 */
KosmicTaskController = {
	/*
	 
	 objectAsString
	 
	 */
	objectAsString : function(theObject) { 
		var result = JSON.stringify(theObject); 
		
		if (result.substr(0,3) !== "---") {
			result = "---\n" + result;
		}
		
		return result;
	} ,
	
	
	/*
	 
	 printObject
	 
	 */
	printObject : function(theObject) { return this.objectAsString(theObject); }
};