//
//  MGSTaskVariablesViewController.h
//  KosmicTask
//
//  Created by Jonathan on 06/04/2013.
//
//

#import <Cocoa/Cocoa.h>

@class MGSScript;

@interface MGSTaskVariablesViewController : NSViewController
{
    IBOutlet NSTableView *_taskVariablesTableView;
    MGSScript *_script;
    NSArrayController *_taskVariablesArrayController;
}

@property MGSScript *script;

- (IBAction)popUpButtonMenuItemSelected:(id)sender;
- (IBAction)variableNameChanged:(id)sender;
@end
