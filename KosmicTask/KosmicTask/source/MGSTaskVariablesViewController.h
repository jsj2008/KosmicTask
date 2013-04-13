//
//  MGSTaskVariablesViewController.h
//  KosmicTask
//
//  Created by Jonathan on 06/04/2013.
//
//

#import <Cocoa/Cocoa.h>

@class MGSScript;

@protocol MGSTaskVariablesViewControllerDelegateProtocol <NSObject>
- (void)taskVariablesController:(id)sender modifiedParameterAtIndex:(NSInteger)index;
@end

@interface MGSTaskVariablesViewController : NSViewController
{
    IBOutlet NSTableView *_taskVariablesTableView;
    MGSScript *_script;
    NSArrayController *_taskVariablesArrayController;
    id <MGSTaskVariablesViewControllerDelegateProtocol> delegate;
}

@property MGSScript *script;
@property id <MGSTaskVariablesViewControllerDelegateProtocol> delegate;

- (IBAction)popUpButtonMenuItemSelected:(id)sender;
- (IBAction)variableNameChanged:(id)sender;
@end
