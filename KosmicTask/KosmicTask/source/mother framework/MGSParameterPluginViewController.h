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

enum _MGSProcessParameterPlist {
	MGSProcessParameterPlistForSave = 0,
};
typedef NSInteger MGSProcessParameterPlist;

@class MGSParameterPlugin;
@class MGSParameterPluginViewController;

@protocol MGSParameterPluginViewControllerDelegate
@optional
- (void)parameterSubViewDidResize:(MGSParameterPluginViewController *)controller oldSize:(NSSize)oldSize;
- (void)pluginViewWantsNewSize:(NSSize)size;
@end

@interface MGSParameterPluginViewController : NSViewController {

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
	id delegate;
	NSSize oldFrameSize;
	NSString *label;
	NSString *_parameterDescription;
}

@property (nonatomic) BOOL canDragHeight;
@property (nonatomic) BOOL canDragMiddleView;
@property (nonatomic) BOOL modelDataModified;
@property MGSParameterPlugin *plugin;
@property (nonatomic) id parameterValue;
@property BOOL updatesDocumentEdited;
@property BOOL sendAsAttachment;
@property (getter=isValid) BOOL valid;
@property (copy) NSString *validationString;
@property (getter=isDefaultValueSelected) BOOL defaultValueSelected;
@property id delegate;
@property (copy) NSString *label;
@property (copy) NSString *parameterDescription;

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
- (void)updateSubview:(NSView *)subview resize:(BOOL)resize;
- (void)updateFrameSize:(NSSize)newSize;
- (BOOL)validateParameterValue:(id)newValue;
@end
