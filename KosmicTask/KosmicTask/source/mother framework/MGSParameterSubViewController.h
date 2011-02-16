//
//  MGSParameterSubViewController.h
//  Mother
//
//  Created by Jonathan on 18/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSViewController.h"
#import "MGSScriptPlist.h"
#import "NSDictionary_Mugginsoft.h"

typedef enum _MGSProcessParameterPlist {
	MGSProcessParameterPlistForSave = 0,
}  MGSProcessParameterPlist;

@class MGSParameterPlugin;

@interface MGSParameterSubViewController : NSViewController {

@private
	id _parameterValue;
	BOOL _canDragHeight;
	BOOL _canDragMiddleView;
	NSMutableDictionary *_plist;
	BOOL _modelDataModified;
	MGSParameterPlugin *_plugin;
	BOOL _sendAsAttachment;
	BOOL _updatesDocumentEdited;
	BOOL _valid;
	NSString *_validationString;
	BOOL _defaultValueSelected;
}

@property BOOL canDragHeight;
@property BOOL canDragMiddleView;
@property BOOL modelDataModified;
@property MGSParameterPlugin *plugin;
@property id parameterValue;
@property BOOL updatesDocumentEdited;
@property BOOL sendAsAttachment;
@property (getter=isValid) BOOL valid;
@property (copy) NSString *validationString;
@property (getter=isDefaultValueSelected) BOOL defaultValueSelected;

- (NSMutableDictionary *)plist;	// access by subclasses only

- (id)initWithNibName:(NSString *)nibNameOrNil;
- (BOOL)setParameterPlist:(NSMutableDictionary *)plist;
- (NSMutableDictionary *)parameterPlist;
- (void)initialiseFromPlist;
- (void)updatePlist;
- (id)defaultValue;
- (void)setDefaultValue:(id)value;
- (void)resetToDefaultValue;
- (void)processPlist:(MGSProcessParameterPlist)processOperation;
@end
