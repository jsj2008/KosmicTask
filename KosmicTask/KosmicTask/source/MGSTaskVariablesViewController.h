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
    MGSScript *__weak _script;
    NSArrayController *_taskVariablesArrayController;
    id <MGSTaskVariablesViewControllerDelegateProtocol> __unsafe_unretained _delegate;
}

@property (weak) MGSScript *script;
@property (unsafe_unretained) id <MGSTaskVariablesViewControllerDelegateProtocol> delegate;

- (IBAction)popUpButtonMenuItemSelected:(id)sender;
@end
