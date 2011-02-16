//
//  MGSSettingsOutlineViewController.h
//  KosmicTask
//
//  Created by Jonathan on 02/10/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MGSLanguagePropertyManager;
@class MGSLanguageProperty;

@interface MGSSettingsOutlineViewController : NSViewController {
	id delegate;
	NSMutableArray *settingsTree;
	BOOL documentEdited;
	BOOL editable;
	MGSLanguagePropertyManager *languagePropertyManager;
	MGSLanguageProperty *selectedLanguageProperty;
	MGSLanguageProperty *editedLanguageProperty;
	
	// views
	IBOutlet NSOutlineView  *settingsOutlineView;
	IBOutlet NSPopUpButtonCell *smallPopUpButtonCell;
	IBOutlet NSTextView *settingsTextView;
	
	// data controllers
	IBOutlet NSTreeController *settingsTreeController;
}

@property id delegate;
@property BOOL documentEdited;
@property BOOL editable;
@property (copy) NSMutableArray *settingsTree;
@property (assign) MGSLanguagePropertyManager *languagePropertyManager;
@property (assign) MGSLanguageProperty *selectedLanguageProperty;
@property (assign) MGSLanguageProperty *editedLanguageProperty;

@end
