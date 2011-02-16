//
//  MGSAppController.m
//  KosmicTaskHost
//
//  Created by Jonathan on 28/04/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSAppController.h"

NSString *mgs_taskClass = @"KosmicTask";
NSString *mgs_taskMethod = @"execute:";

/*
 
 don't be tempted to enable GC.
 
 we are linking against a lot of frameworks and some don't support GC.
 
 */
@implementation MGSAppController

/*
 
 - applicationDidFinishLaunching:
 
 */
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	NSString *taskClass = mgs_taskClass;
	NSString *taskMethod = mgs_taskMethod;
	
	/*
	 
	 Create an object with class taskClass.
	 
	 This class must be pre-loaded by the bridge from
	 source files in the bundle.
	 
	 */
	
	// get class object
	Class klass = NSClassFromString(taskClass);
	if (!klass) {
		NSLog(@"Object class does not exist: %@", taskClass);
		[NSApp terminate:self];
	}
	
	// get instance
	id taskObject = [[klass alloc] init];
	if (!taskObject) {
		NSLog(@"Cannot instantiate object of class: %@", taskClass);
		[NSApp terminate:self];
	}
	
	// get method selector
	SEL sel = NSSelectorFromString(taskMethod);
	
	// validate selector
	if (![taskObject respondsToSelector:sel]) {
		NSLog(@"Object of class: %@ does not respond to : %@", taskClass, taskMethod);
		[NSApp terminate:self];
	}
	
	// perform it
	id result = [taskObject performSelector:sel withObject:nil];
	
#pragma unused(result)
}
/*
// get all files on the desktop that have the .py extension
- (NSArray*) validScriptFiles {
	// use the desktop for our simple purposes
	NSString *desktopPath = [@"~/Desktop" stringByStandardizingPath];
	
	// get all files on the desktop
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *desktopFiles = [fileManager contentsOfDirectoryAtPath:desktopPath
															 error:NULL];
	
	NSMutableArray *paths = [NSMutableArray array];
	
	// only find files that have .py extension, and add their full filenames
	for (NSString *desktopFile in desktopFiles)
		if ([[desktopFile pathExtension] caseInsensitiveCompare: @"py"] == NSOrderedSame)
			[paths addObject:[desktopPath stringByAppendingPathComponent:desktopFile]];
	
	// sort files alphabetically by their filename
	[paths sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		id name1 = [[obj1 lastPathComponent] stringByDeletingPathExtension];
		id name2 = [[obj1 lastPathComponent] stringByDeletingPathExtension];
		return [name1 caseInsensitiveCompare: name2];
	}];
	
	return paths;
}

// when the Scripts menu is being shown, show the list of available scripts
- (void)menuNeedsUpdate:(NSMenu*)menu {
	[menu removeAllItems];
	
	for (NSString *fullPath in [self validScriptFiles]) {
		// add a menu item for each script
		NSString *scriptTitle = [[[fullPath lastPathComponent] stringByDeletingPathExtension] capitalizedString];
		
		// our document subclass implements the -runScript: selector
		NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:scriptTitle
													   action:@selector(runScript:)
												keyEquivalent:@""] autorelease];
		
		[item setRepresentedObject:fullPath];
		
		[menu addItem:item];
	}
	
	if ([menu numberOfItems] == 0) {
		NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:@"No Scripts"
													   action:NULL
												keyEquivalent:@""] autorelease];
		[menu addItem:item];
	}
}
 
 */

@end
