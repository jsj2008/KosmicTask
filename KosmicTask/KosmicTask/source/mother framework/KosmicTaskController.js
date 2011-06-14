/*

 KosmicTaskController is predefined in the executing context
 as suplied by the task runner.
 
 KosmicTaskController provides the following methods:
 
 log() - Logs a value to stderr.
 
 We define additional methods here.
 
 */

/*
 
 objectAsString
 
 */
KosmicTaskController.objectAsString = function(theObject) { 
	var result = JSON.stringify(theObject); 
	
	if (result.substr(0,3) !== "---") {
		result = "---\n" + result;
	}
	
	return result;
}


/*
 
 printObject
 
 */
KosmicTaskController.printObject = function(theObject) { return this.objectAsString(theObject); }

/*
 
 Global functions
 
 */
function log(str) {	KosmicTaskController.log('' + str);	}


