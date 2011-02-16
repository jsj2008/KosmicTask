<?php
	
require_once "spyc.php";
	
class KosmicTaskController {
		
	/*
		 
	 objectToString
		 
	*/
	public static function objectToString($object) {
			
		// get native object as YAML
		$result = Spyc::YAMLDump($object);
			
		return $result;
	}
		
	/*
		 
	 printObject
		 
	 */
	public static function printObject($object) {
			
		// get native object as YAML
		$result = self::objectToString($object);
			
		print $result;
	}
		
}