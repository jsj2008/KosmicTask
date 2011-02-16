/*
 *  MGSMotherExportPlugin.h
 *  Mother
 *
 *  Created by Jonathan on 19/05/2008.
 *  Copyright 2008 Mugginsoft. All rights reserved.
 *
 */


#import <Cocoa/Cocoa.h>

@protocol MGSMotherExportPlugin

@required;
// Returns the version of the interface you're implementing.
// Return 0 here or future versions may look for features you don't have!
- (unsigned)interfaceVersion;

// Returns what to display in the export menu.
- (NSString *)menuItemString;

// export the object
- (void)export:(id)object toPath:(NSString *)path;

// Returns the window controller for the settings configuration window.
- (NSWindowController *)configurationWindowController;

@end