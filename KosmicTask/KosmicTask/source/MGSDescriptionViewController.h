//
//  MGSDescriptionViewController.h
//  Mother
//
//  Created by Jonathan on 13/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSParameterViewController.h"

@class MGSScriptParameter;
@class MGSParameterDescriptionViewController;

@protocol MGSDescriptionViewController 

@optional
- (void)descriptionViewDidResize:(MGSParameterDescriptionViewController *)controller oldSize:(NSSize)oldSize;
@end

@interface MGSParameterDescriptionViewController : NSViewController {
	
	// description
	IBOutlet NSButton *descriptionDisclosureButton;		// disclosure button
	IBOutlet NSScrollView *descriptionScrollView;		// description scroll view
	IBOutlet NSTextView *description;					// description text view
	IBOutlet NSTextField *descriptionTitle;				// parameter description title
	IBOutlet NSImageView *descriptionImageView;			// image
	
	//MGSScriptParameter *_scriptParameter;
	MGSParameterMode _mode;
	
	//NSRect _initialViewFrame;
	IBOutlet id _delegate;
	BOOL _layoutHasOccurred;
}

@property (readonly) MGSParameterMode mode;
@property id delegate;

-(id)initWithMode:(MGSParameterMode)mode;
- (IBAction)disclosureButtonClick:(id)sender;
//- (void)setScriptParameter:(MGSScriptParameter *)aScriptParameter;
//- (void)initialiseForMode:(MGSParameterMode)mode;
- (void)toggleDescriptionDisclosure;
- (NSSize)initialLayoutSize;
@end
