//
//  MGSOpenSourceFileAccessoryViewController.h
//  KosmicTask
//
//  Created by Jonathan on 22/10/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define MGS_AV_REPLACE_TEXT 0
#define MGS_AV_APPEND_TEXT 1

@interface MGSOpenSourceFileAccessoryViewController : NSViewController {
	IBOutlet NSPopUpButton *scriptTypePopUp;
	IBOutlet NSMatrix *textHandlingMatrix;
	IBOutlet NSArrayController *languagePluginArrayController;
	NSString *scriptType;
	NSInteger selectedTextHandlingTag;
	BOOL textHandlingEnabled;
}

- (void)setScriptTypeForFile:(NSString *)filename;
@property (copy, readonly) NSString *scriptType;
@property NSInteger selectedTextHandlingTag;
@property BOOL textHandlingEnabled;

@end
