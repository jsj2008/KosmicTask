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
    id <MGSTaskVariablesViewControllerDelegateProtocol> __weak _delegate;
}

@property (nonatomic) MGSScript *script;
@property (weak) id <MGSTaskVariablesViewControllerDelegateProtocol> delegate;

- (IBAction)popUpButtonMenuItemSelected:(id)sender;
@end
