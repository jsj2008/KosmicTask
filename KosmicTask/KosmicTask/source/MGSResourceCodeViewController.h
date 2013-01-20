//
//  MGSResourceCodeViewController.h
//  KosmicTask
//
//  Created by Jonathan on 17/01/2013.
//
//

#import <Cocoa/Cocoa.h>
#import <MGSFragaria/MGSFragaria.h>

@class MGSFragaria;
@class MGSLanguageTemplateResource;
@class MGSScript;

enum {
    kMGSScriptCodeSegmentIndex = 0,
    kMGSTemplateCodeSegmentIndex
};
typedef NSUInteger MGSCodeSegmentIndex;

@interface MGSResourceCodeViewController : NSViewController {
    MGSFragaria *fragaria;	// fragaria instance
    NSTextView *editorTextView;
    IBOutlet NSView *editorHostView;
    BOOL editable;
    BOOL resourceEditable;
    MGSLanguageTemplateResource *languageTemplateResource;
    MGSScript *script;
    BOOL documentEdited;
    MGSCodeSegmentIndex selectedCodeSegmentIndex;
    IBOutlet NSSegmentedControl *codeSegmentedControl;
    BOOL templateDisplayed;
    IBOutlet id delegate;
    
}

@property BOOL editable;
@property BOOL resourceEditable;
@property (retain) MGSLanguageTemplateResource *languageTemplateResource;
@property MGSScript *script;
@property BOOL documentEdited;
@property MGSCodeSegmentIndex selectedCodeSegmentIndex;
@property BOOL templateDisplayed;
@property id delegate;

- (NSString *)string;
@end
