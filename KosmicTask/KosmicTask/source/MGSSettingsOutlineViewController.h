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
	__weak id delegate;
	NSMutableArray *settingsTree;
	BOOL documentEdited;
	BOOL editable;  // view editable
    BOOL resourceEditable;	// resource editable
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

@property (weak) id delegate;
@property BOOL documentEdited;
@property (nonatomic) BOOL editable;
@property BOOL resourceEditable;
@property (copy, nonatomic) NSMutableArray *settingsTree;
@property (strong, nonatomic) MGSLanguagePropertyManager *languagePropertyManager;
@property (strong) MGSLanguageProperty *selectedLanguageProperty;
@property (strong) MGSLanguageProperty *editedLanguageProperty;

@end
