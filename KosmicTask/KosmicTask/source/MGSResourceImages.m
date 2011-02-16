//
//  MGSResourceImages.m
//  Mother
//
//  Created by Jonathan on 16/11/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSMother.h"
#import "MGSResourceImages.h"

NSString *MGSImageCollectionKeyImage = @"icon";
NSString *MGSImageCollectionKeyName =  @"name";
NSString *MGSImageCollectionKeyLocation =  @"location";
NSString *MGSResourceGroupIcons = @"ResourceGroupIcons";


@implementation MGSResourceImages

/*
 
 image dictionary array at path
 
 */
+ (NSMutableArray *)imageDictionaryArrayAtPath:(NSString *)path
{
	// Determine the content of the collection view by reading in the plist "icons.plist",
	// and add extra "named" template images with the help of NSImage class.
	//
	NSMutableArray	*tempArray = [[NSMutableArray alloc] init];
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	// enumerate path
	NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:path];
	if (!dirEnum) {
		MLog(DEBUGLOG, @"cannot enumerate image path: %@", path);	
		return tempArray;
	}
	
	NSString *file;
	while ((file = [dirEnum nextObject])) {
		
		// want to copy files only
		if (![[[dirEnum fileAttributes] objectForKey:NSFileType] isEqualToString: NSFileTypeRegular]) {
			[dirEnum skipDescendents];	// don't enumerate directory any further
			continue;
		}
		
		// want to scan extension
		//if (NSOrderedSame != [[file pathExtension] caseInsensitiveCompare:MGSScriptPlistExt]) {	
		//	continue;
		//}
		
		// attempt to load the image from the  file
		NSString *iconName = file;
		NSImage *picture = [[NSImage alloc] initWithContentsOfFile:[path stringByAppendingPathComponent:file]];
		if (!picture) {
			continue;
		}
		
		[tempArray addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:
							   picture, MGSImageCollectionKeyImage,
							   iconName, MGSImageCollectionKeyName,
							   MGSResourceGroupIcons, MGSImageCollectionKeyLocation,
							   nil]];
	}
	
	return tempArray;
}

@end
