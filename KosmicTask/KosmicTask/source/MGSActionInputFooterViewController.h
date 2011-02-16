//
//  MGSActionInputFooterViewController.h
//  Mother
//
//  Created by Jonathan on 29/07/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MGSActionOptionsViewController;
@class MGSActionInfoViewController;
@class MGSActionInputFooterViewController;
@class MGSActionDescriptionViewController;
@class MGSTaskSpecifier;

@protocol MGSActionInputFooterViewController
- (void)footerViewDidResize:(MGSActionInputFooterViewController *)controller oldSize:(NSSize)oldSize;
@end

@interface MGSActionInputFooterViewController : NSViewController {
	id _delegate;
	IBOutlet NSButton *descriptionButton;
	IBOutlet NSButton *optionsButton;
	IBOutlet NSButton *infoButton;
	IBOutlet NSButton *resetButton;
	IBOutlet NSView *buttonView;
	NSArray *_exclusiveButtonArray;	
	
	MGSActionOptionsViewController * _actionOptionsViewController;
	MGSActionInfoViewController * _actionInfoViewController;
	MGSActionDescriptionViewController *_actionDescriptionViewController;
	
	NSViewController *_activeViewController;
	NSRect _initialViewRect;
	MGSTaskSpecifier *_actionSpecifier;
}

@property id delegate;
@property (assign) MGSTaskSpecifier *actionSpecifier;

- (IBAction)optionsClick:(id)sender;
- (IBAction)infoClick:(id)sender;
- (IBAction)descriptionClick:(id)sender;
- (IBAction)resetAll:(id)sender;
- (void)setResetEnabled:(BOOL)newValue;
- (BOOL)isResetEnabled;
@end
