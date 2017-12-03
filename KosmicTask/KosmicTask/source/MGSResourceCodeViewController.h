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
@class PSMTabBarControl;

enum {
    kMGSScriptCodeSegmentIndex = 0,
    kMGSTemplateCodeSegmentIndex = 1,
    kMGSVariablesCodeSegmentIndex = 2,
};
typedef NSUInteger MGSCodeSegmentIndex;

@interface MGSResourceCodeViewController : NSViewController {
    MGSFragaria *fragaria;	// fragaria instance
    NSTextView *editorTextView;
    IBOutlet NSView *editorHostView;
    BOOL editable;
    BOOL resourceEditable;
    MGSLanguageTemplateResource *languageTemplateResource;
    MGSScript *__weak script;
    BOOL documentEdited;
    MGSCodeSegmentIndex selectedCodeSegmentIndex;
    IBOutlet NSSegmentedControl *codeSegmentedControl;
    IBOutlet id __weak delegate;
    BOOL textViewEditable;
    BOOL textEditable;
    IBOutlet PSMTabBarControl *tabBar;
}

@property BOOL editable;
@property (nonatomic) BOOL resourceEditable;
@property (strong, nonatomic) MGSLanguageTemplateResource *languageTemplateResource;
@property (weak, nonatomic) MGSScript *script;
@property BOOL documentEdited;
@property (nonatomic) MGSCodeSegmentIndex selectedCodeSegmentIndex;
@property (weak) id delegate;


- (NSString *)scriptString;
@end
