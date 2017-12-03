//
//  MGSScriptViewController.h
//  Mother
//
//  Created by Jonathan on 22/02/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OSAKit/OSAKit.h>
#import "MGSClientNetRequest.h"
#import "MGSViewDelegateProtocol.h"
#import <MGSFragaria/MGSFragaria.h>

@class MGSTaskSpecifier;
@class MGSScriptViewController;
@class MGSScript;

@protocol MGSScriptViewController
- (void)scriptViewLoaded:(MGSScriptViewController *)controller;
@end

@interface MGSScriptViewController : NSViewController <MGSNetRequestOwner, MGSViewDelegateProtocol> {

	MGSTaskSpecifier *_taskSpec;
	MGSScript *_taskScript;
	MGSTaskSpecifier *_pendingTaskSpec;
	NSInteger _editMode;
	unsigned long int _requestID;
	id __unsafe_unretained _delegate;
	BOOL _scriptTextChanged;
    BOOL _stringHasBeenSet;
	BOOL _editable;
	
	NSString *__weak _scriptTemplateSource;
	NSString *_scriptType;
	
	NSView *_currentHostView;
	NSTextView *_currentTextView;
	BOOL ignoreScriptSourceChange;
	
	// no script handling
	IBOutlet NSView *_noScriptHostView;	// show when no script available

	// OSA editor
	IBOutlet NSView *_osaHostView;
	IBOutlet NSScrollView *_osaScrollView;
	IBOutlet OSAScriptView *_osaTextView;
	
	// Fragaria editor
	MGSFragaria *_fragaria;	// fragaria instance
	IBOutlet NSView *_fragariaHostView; // fragria host view
	NSTextView *_fragariaTextView;
}

@property (strong, nonatomic) MGSTaskSpecifier *taskSpec;
@property (unsafe_unretained) id delegate;
@property (readonly) BOOL scriptTextChanged;
@property (weak, readonly) NSString *scriptTemplateSource;


- (NSData *)scriptSourceRTFData;
- (NSString *)scriptSource;
- (NSAttributedString *)scriptAttributedSource;
- (void)setEditMode:(NSInteger)mode;
- (void)setEditable:(BOOL)editable;
- (void)setSelectedRange:(NSRange)range;
- (void)setSelectedRange:(NSRange)range options:(NSDictionary *)options;
- (void)setSelectedRanges:(NSArray *)ranges;
- (void)setSelectedRanges:(NSArray *)ranges options:(NSDictionary *)options;
- (void)dispose;
- (void)printDocument:(id)sender;
- (BOOL)documentPrintable;
- (void)makeFirstResponder:(NSResponder *)responder;
- (NSView *)initialFirstResponder;
- (void)shiftLeftAction:(id)sender;
- (NSUndoManager *)undoManager;
- (void)textDidEndEditing:(NSNotification *)aNotification;
- (void)applyDefaultFormatting:(NSMutableAttributedString *)attributedString;
- (void)insertString:(NSString *)text;
- (void)setString:(NSString *)value;
- (NSTextView *)scriptTextView;
- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)string options:(NSDictionary *)options;

@end
