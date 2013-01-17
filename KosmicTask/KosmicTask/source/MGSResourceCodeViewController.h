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

@interface MGSResourceCodeViewController : NSViewController {
    MGSFragaria *fragaria;	// fragaria instance
    NSTextView *editorTextView;
    IBOutlet NSView *editorHostView;
    BOOL editable;
    BOOL resourceEditable;
}

@property BOOL editable;
@property BOOL resourceEditable;

- (NSString *)string;
- (void)setString:(NSString *)string;
- (void)setSyntaxDefinition:(NSString *)syntaxDefinition;

@end
