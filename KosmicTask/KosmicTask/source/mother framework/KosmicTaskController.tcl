# Register the package
package provide KosmicTaskController 1.0

package require yaml

#
# Create the namespace
#
namespace eval ::KosmicTaskController {
    
	# Export commands
    namespace export printObject objectToString

}

#
# objectToString
#
proc ::KosmicTaskController::objectToString {object} {

	# convert object to yaml.
	# catching seems primitive but it seems the only way to direct
	# our object to the required function
	
	set result "cannot convert to YAML"
	
	set fail [catch {set result [::yaml::huddle2yaml $object]}];
	
	if {$fail} {
		set fail [catch {set result [::yaml::dict2yaml $object]}];
	} 
	
	if {$fail} {
		set fail [catch {set result [::yaml::list2yaml $object]}];
	} 	
	
	return $result
}

#
# printObject
#
proc ::KosmicTaskController::printObject {object} {

    set result [::KosmicTaskController::objectToString $object];
	puts $result;
	
	return
}
