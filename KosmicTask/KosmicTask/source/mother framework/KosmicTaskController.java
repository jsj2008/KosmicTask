package com.mugginsoft;

import org.yaml.snakeyaml.Yaml;
import java.util.Scanner;

public class KosmicTaskController
{ 
	/*
	 
	 objectToString
	 
	 */
	public static String objectToString(Object resultObject)
    {
    			
    	// get native array as YAML array
    	Yaml yaml = new Yaml();
		String result = yaml.dump(resultObject);
		Scanner sc = new Scanner(result);
		
		if (!sc.hasNext("---")) {
			result = "---\n" + result;
		}
		return result;
	}
	
	/*
	 
	 printObject
	 
	 */
	public static void printObject(Object resultObject)
    {
		String result = objectToString(resultObject);
		
    	System.out.println(result);
	}
}
