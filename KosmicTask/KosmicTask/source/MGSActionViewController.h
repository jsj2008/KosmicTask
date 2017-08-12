//
//  MGSActionViewController.h
//  Mother
//
//  Created by Jonathan on 06/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSRoundedPanelViewController.h"
#import "MGSParameterViewController.h"

@class MGSTaskSpecifier;
@class MGSActionView;
@class MGSActionViewController;
@class MGSTextPanelViewController;
@class MGSActionInputFooterViewController;

@protocol MGSActionViewController
- (void)resetToDefaultValue;
@end

@interface MGSActionViewController : MGSRoundedPanelViewController {
@private
	MGSParameterMode _mode;
	MGSTaskSpecifier *_task;
	IBOutlet NSImageView *leftBannerImageView;
	IBOutlet NSImageView *rightBannerImageView;
	BOOL _invertedLeftBannerImage;
	MGSTextPanelViewController *_descriptionViewController;
	MGSActionInputFooterViewController *_actionInputFooterViewController;
    NSColor *_parameterCountLabelColourDisabled;
    NSColor *_parameterCountLabelColourEnabled;
}

@property (strong) MGSTaskSpecifier *action;
@property BOOL invertedLeftBannerImage;

-(id)initWithMode:(MGSParameterMode)mode ;
- (void)updateParameterCountDisplay;
- (MGSActionView *)actionView;
- (void)setFrameSize:(NSSize)size;
- (void)setHighlighted:(BOOL)value;
- (void)resetToDefaultValue;
- (void)setResetEnabled:(BOOL)newValue;
- (BOOL)isResetEnabled;
@end
