#import <Cocoa/Cocoa.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CoreServices/CoreServices.h> 
#import "MGSScriptPlist.h"

/* -----------------------------------------------------------------------------
   Step 1
   Set the UTI types the importer supports
  
   Modify the CFBundleDocumentTypes entry in Info.plist to contain
   an array of Uniform Type Identifiers (UTI) for the LSItemContentTypes 
   that your importer can handle
  
   ----------------------------------------------------------------------------- */

/* -----------------------------------------------------------------------------
   Step 2 
   Implement the GetMetadataForFile function
  
   Implement the GetMetadataForFile function below to scrape the relevant
   metadata from your document and return it as a CFDictionary using standard keys
   (defined in MDItem.h) whenever possible.
   ----------------------------------------------------------------------------- */

/* -----------------------------------------------------------------------------
   Step 3 (optional) 
   If you have defined new attributes, update the schema.xml file
  
   Edit the schema.xml file to include the metadata keys that your importer returns.
   Add them to the <allattrs> and <displayattrs> elements.
  
   Add any custom types that your importer requires to the <attributes> element
  
   <attribute name="com_mycompany_metadatakey" type="CFString" multivalued="true"/>
  
   ----------------------------------------------------------------------------- */



/* -----------------------------------------------------------------------------
    Get metadata attributes from file
   
   This function's job is to extract useful information your file format supports
   and return it as a dictionary
   ----------------------------------------------------------------------------- */

Boolean GetMetadataForFile(void* thisInterface, 
			   CFMutableDictionaryRef attributes, 
			   CFStringRef contentTypeUTI,
			   CFStringRef pathToFile)
{
	#pragma unused(thisInterface)
	#pragma unused(contentTypeUTI)
	
	/* Pull any available metadata from the file at the specified path */
    /* Return the attribute keys and attribute values in the dict */
    /* Return true if successful, false if there was no data provided */
    Boolean success=NO;
    
	// Don't assume that there is an autorelease pool around the calling of this function.
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSMutableDictionary *scriptDict;

	NSAttributedString *attributedString = nil;;
	NSData *dataRTF = nil;
	
    // load the document at the specified location
    scriptDict = [[[NSMutableDictionary alloc] initWithContentsOfFile:(NSString *)pathToFile] autorelease];
    if (scriptDict)
    {
		// prepare text content string
		NSMutableString *textContent = [[[NSMutableString alloc] init] autorelease];
		
		id dictObject = nil;
		
		// set the kMDItemTitle attribute to the Name
		dictObject = [scriptDict objectForKey:MGSScriptKeyName];
		if ([dictObject isKindOfClass:[NSString class]]) {
			[(NSMutableDictionary *)attributes setObject:dictObject forKey:(NSString *)kMDItemTitle];
		}
		
		// set the kMDItemKeywords attribute to the ScriptType
		dictObject = [scriptDict objectForKey:MGSScriptKeyScriptType];
		if ([dictObject isKindOfClass:[NSString class]]) {
			[(NSMutableDictionary *)attributes setObject:[NSArray arrayWithObject:dictObject] forKey:(NSString *)kMDItemKeywords];
		 }		
		
		// set the kMDItemAuthors attribute to an array containing the single Author
		dictObject = [scriptDict objectForKey:MGSScriptKeyAuthor];
		if ([dictObject isKindOfClass:[NSString class]]) {
			[(NSMutableDictionary *)attributes setObject:[NSArray arrayWithObject:dictObject] forKey:(NSString *)kMDItemAuthors];
		}

		// set the kMDItemDescription attribute to the Description
		dictObject = [scriptDict objectForKey:MGSScriptKeyDescription];
		if ([dictObject isKindOfClass:[NSString class]]) {
			NSString *description = dictObject;

			// get long description
			dataRTF = [scriptDict objectForKey:MGSScriptKeyLongDescription];
			if ([dataRTF isKindOfClass:[NSData class]]) {
				
				// try RTFD first. if the format is RTF the init will fail
				attributedString = [[[NSAttributedString alloc] initWithRTFD:dataRTF documentAttributes:nil] autorelease];
				if (!attributedString) {
					attributedString = [[[NSAttributedString alloc] initWithRTF:dataRTF documentAttributes:nil] autorelease];
				}
				if (!attributedString) [NSException raise:NSGenericException format:@"Could not extract long description RTF data"];
					
				description = [description stringByAppendingString:@" "];
				description = [description stringByAppendingString:[attributedString string]];
				
			}
			
			// set description attribute
			[(NSMutableDictionary *)attributes setObject:description forKey:(NSString *)kMDItemDescription];

			// add description to content
			[textContent appendString:description];
			[textContent appendString:@" "];
		}
		
		// script source.
		NSDictionary *codeDict = [scriptDict objectForKey:MGSScriptKeyCode];
		if ([codeDict isKindOfClass:[NSDictionary class]]){
			
			// get data rep and validate
			dataRTF = [codeDict objectForKey:MGSScriptKeySourceRTFData];			
			if ([dataRTF isKindOfClass:[NSData class]]) {
				
				attributedString = [[[NSAttributedString alloc] initWithRTF:dataRTF documentAttributes:NULL] autorelease];
				if (!attributedString) [NSException raise:NSGenericException format:@"Could not extract source RTF data"];
				NSString *script = [attributedString string];
				
				// define custom attribute
				[(NSMutableDictionary *)attributes setObject:script forKey:@"com_mugginsoft_kosmictask_script"];
				
				// add script to content
				[textContent appendString:script];
				[textContent appendString:@" "];
			}

		}
		
		// remove the Data type keys and form content string from property list data
		[scriptDict removeObjectForKey:MGSScriptKeyLongDescription];
		[scriptDict removeObjectForKey:MGSScriptKeyCode];
		
		// get main content data
		NSString *errorString = nil;
		NSData *contentData = [NSPropertyListSerialization dataFromPropertyList:scriptDict format:NSPropertyListXMLFormat_v1_0 errorDescription:&errorString];
		if (contentData == NULL) [NSException raise:NSGenericException format:@"Could not parse file as property list (%@),", errorString];
	 
		// get main content as string
		// note that the XML tags remain
		NSString *mainContent = [[[NSString alloc] initWithData:contentData encoding:NSUTF8StringEncoding] autorelease];
		if (mainContent == NULL) [NSException raise:NSGenericException format:@"Could not read content"];
	
		// append main content
		[textContent appendString:mainContent];
		
		// set content attribute
		[(NSMutableDictionary *)attributes setObject:textContent forKey:(NSString *)kMDItemTextContent];
		
		// return YES so that the attributes are imported
		success=YES;

    }
    [pool release];
    return success;
}
