//
//  MGSOpenSourceFileAccessoryViewController.m
//  KosmicTask
//
//  Created by Jonathan on 22/10/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSOpenSourceFileAccessoryViewController.h"
#import "MGSLanguagePluginController.h"

// class extension
@interface MGSOpenSourceFileAccessoryViewController()
@property (copy) NSString *scriptType;
@end

static char MGSScriptTypeSelectionIndexContext;

@implementation MGSOpenSourceFileAccessoryViewController

@synthesize scriptType, selectedTextHandlingTag, textHandlingEnabled;

#pragma mark -
#pragma mark Instance 
/*
 
 init
 
 */
- (id)init
{
	if ((self = [super initWithNibName:@"OpenSourceFileAccessoryView" bundle:nil])) {
		selectedTextHandlingTag = MGS_AV_APPEND_TEXT;
		textHandlingEnabled = YES;
	}
	return self;
}

/* 
 
 awake from nib
 
 */
- (void)awakeFromNib
{
	NSArray *languagePlugins = [[MGSLanguagePluginController sharedController] instances];
	
	NSDictionary *bindingOptions = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSNumber numberWithBool:YES], NSInsertsNullPlaceholderBindingOption,
									NSLocalizedString(@"<Default>",@"Default script type placeholder - appears in open file popup menu"), NSNullPlaceholderBindingOption, nil];
	
	[languagePluginArrayController setContent:languagePlugins];
	
	// type popup bindings
	[scriptTypePopUp bind:NSContentBinding toObject:languagePluginArrayController withKeyPath:@"arrangedObjects" options:nil];
	[scriptTypePopUp bind:NSContentValuesBinding toObject:languagePluginArrayController withKeyPath:@"arrangedObjects.scriptType" options:bindingOptions];
	[scriptTypePopUp bind:NSSelectedIndexBinding toObject:languagePluginArrayController withKeyPath:@"selectionIndex" options:nil];
	
	// text handling matrix bindings
	[textHandlingMatrix bind:NSSelectedTagBinding toObject:self withKeyPath:@"selectedTextHandlingTag" options:nil];
	[textHandlingMatrix bind:NSEnabledBinding toObject:self withKeyPath:@"textHandlingEnabled" options:nil];

	// observing
	[languagePluginArrayController addObserver:self forKeyPath:@"selectionIndex" options:NSKeyValueObservingOptionNew context:(void *)&MGSScriptTypeSelectionIndexContext]; 
}

#pragma mark -
#pragma mark KVO

/*
 
 -observeValueForKeyPath:ofObject:change:context:
 
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
#pragma unused(keyPath)
#pragma unused(object)
#pragma unused(change)
	
	// script type selection
	if (context == &MGSScriptTypeSelectionIndexContext) {
		
		NSInteger idx = [languagePluginArrayController selectionIndex];
		
		// check if default selected
		if (idx == NSNotFound) {
			self.scriptType = nil;
		} else {
			MGSLanguagePlugin *plugin = [[languagePluginArrayController arrangedObjects] objectAtIndex:idx];
			self.scriptType = [plugin scriptType];
		}
				
	}
	
}

/*
 
 - setScriptTypeForFile:
 
 */
- (void)setScriptTypeForFile:(NSString *)filename
{
	if (!filename) {
		[languagePluginArrayController setSelectionIndex:NSNotFound];
		return;
	}
	
	NSString *extension = [filename pathExtension];
	MGSLanguagePlugin *plugin = [[MGSLanguagePluginController sharedController] pluginForSourceFileExtension:extension];
	if (!plugin) {
		[languagePluginArrayController setSelectionIndex:NSNotFound];
	} else {
		[languagePluginArrayController setSelectedObjects:[NSArray arrayWithObject:plugin]];
	}
}
@end
