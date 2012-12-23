//
//  MGSParameterViewController.h
//  Mother
//
//  Created by Jonathan on 05/01/2008.
//  Copyright 2008 . All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSRoundedPanelViewController.h"

@class MGSParameterView;
@class MGSScriptParameter;
@class MGSParameterSubEditViewController;
@class MGSParameterSubInputViewController;
@class MGSParameterDescriptionViewController;
@class MGSParameterViewController;
@class MGSParameterPluginInputViewController;

enum _MGSParameterIndexChange {
    kMGSParameterIndexDecrease = 1,
    kMGSParameterIndexIncrease = 0,
};
typedef NSInteger MGSParameterIndexChange;

@protocol MGSParameterViewController

- (void)closeParameterView:(MGSParameterViewController *)controller;
- (void)parameterViewController:(MGSParameterViewController *)sender didChangeResetEnabled:(BOOL)resetEnabled;
- (void)parameterViewController:(MGSParameterViewController *)sender changeIndex:(MGSParameterIndexChange)changeIndex;
- (void)dragParameterView:(MGSParameterViewController *)controller event:(NSEvent *)event;
@end

// parameter mode
enum _MGSParameterMode {
	MGSParameterModeInput = 0,
	MGSParameterModeEdit
};
typedef NSInteger MGSParameterMode;

// parameter type
typedef enum _MGSParameterType {
	MGSNumberParameter = 0, 
	MGSTextParameter,
	MGSDateParameter,
	MGSFileParameter,
} MGSParameterType;

@interface MGSParameterViewController : MGSRoundedPanelViewController {
	
	//IBOutlet NSTextField *index;					// parameter index
	IBOutlet NSTextField *name;						// parameter name
	IBOutlet NSTextField *nameLabel;				// parameter name
	IBOutlet NSTextField *type;						// parameter type
	//IBOutlet NSTextField *value;					// parameter value
	IBOutlet NSPopUpButton *typePopup;				// parameter type popup
	IBOutlet NSImageView *bannerLeftImage;				// left banner image
	IBOutlet NSSegmentedControl *parameterIndexControl;
    
	//
	// circular button.
	// to get the correct redraw behaviour when clicked make sure that the button
	// mode is set to Monentary Change - otherwise the image is no t masked correctly.
	//
	/*
	Setting a Button’s Image
	
	A button can have two images associated with it: normal and alternate. 
	If the button type is NSMomentaryPushInButton, NSPushOnPushOffButton, NSMomentaryLightButton, or NSOnOffButton, 
	 only the normal image is ever displayed. If the button type is NSMomentaryChangeButton or NSToggleButton, 
	 the normal image is displayed when the button’s state is off (NSOffState) and the alternate image is displayed 
	 when the button’s state is on or mixed (NSOnState. or NSMixedState). If you want a button to display different 
	 image for all three states, you must subclass NSButton. (Although switch and radio buttons can display different 
	 images for all three states, there is no public interface for this feature.)
		
		To set the normal image, use setImage:. To set the alternate image, use setAlternateImage:.
	 */
	IBOutlet NSButton *closeButton;				// click to close image view
	
	//IBOutlet NSView *view;							// the enclosing view itself
	NSInteger _displayIndex;
	MGSScriptParameter *_scriptParameter;
	//id _editor;	// object being edited
	//BOOL _nibLoaded;
	
	MGSParameterType _parameterType;
	MGSParameterSubEditViewController *_typeEditViewController;
	MGSParameterSubInputViewController *_typeInputViewController;
	MGSParameterPluginInputViewController *_pluginInputViewController;
	
	MGSParameterMode _mode;	// input or edit mode
	
	IBOutlet MGSParameterDescriptionViewController *_descriptionViewController;
	
	NSString *_parameterName;
	NSString *_parameterDescription;
	BOOL _initialTypePluginLoaded;	// set to YES once a valid parameter type plugin has been loaded
	BOOL _layoutHasOccurred;		// YES when view has been laid out
	
	NSSize _selfLayoutSize;
	NSSize _topLayoutSize;
	NSSize _middleLayoutSize;
	NSSize _bottomLayoutSize;
	BOOL _resetEnabled;
    BOOL _dragging;
    BOOL _mouseDragged;
    NSPoint _lastDragLocation;
    BOOL _canDecreaseDisplayIndex;
    BOOL _canIncreaseDisplayIndex;
}

@property (assign) MGSScriptParameter *scriptParameter;
@property NSInteger displayIndex;
@property MGSParameterType parameterType;
@property (readonly)MGSParameterMode mode;
@property (copy) NSString *parameterName;
@property (copy) NSString *parameterDescription;
@property (readonly) BOOL resetEnabled;
@property BOOL canDecreaseDisplayIndex;
@property BOOL canIncreaseDisplayIndex;

+ (id)parameterTypeMenuDictionaryWithTarget:(id)target action:(SEL)selector;
- (id)initWithMode:(MGSParameterMode)mode;
- (void)buildMenus;
- (void)typePopupMenuItemSelected:(id)sender;
- (void)typePopupMenuItemClicked:(id)sender;
//- (void)initialiseForMode:(MGSParameterMode)mode;
- (IBAction)close:(id)sender;
- (IBAction)changeInputIndexAction:(id)sender;
- (BOOL)isValid;
- (NSString *)validationString;

- (void)mouseDown:(NSEvent *)theEvent;
- (MGSParameterView *)parameterView;
- (void)resetToDefaultValue;
- (void)subview:(NSView *)view wantsNewSize:(NSSize)newSize;

- (BOOL)isHighlighted;
- (void)setIsHighlighted:(BOOL)value;
- (void)selectParmaterTypeWithMenuTag:(NSUInteger)tag;
- (void)updateModel;
- (void)markModelDataAsModified;

@end
