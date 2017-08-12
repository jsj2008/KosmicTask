//
//  MGSActionDeleteWindowController.h
//  Mother
//
//  Created by Jonathan on 29/02/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol MGSActionDeleteWindowControllerDelegate <NSObject>

@required
- (void)confirmDeleteSelectedAction:(BOOL)delete;
@end


@interface MGSActionDeleteWindowController : NSWindowController {
	IBOutlet NSTextField *mainLabel;
	IBOutlet NSButton *deleteButton;
	IBOutlet NSButton *cancelButton;
	id __unsafe_unretained _delegate;
	NSWindow *__weak _modalForWindow;
}

@property (weak) NSWindow *modalForWindow;
@property (unsafe_unretained) id <MGSActionDeleteWindowControllerDelegate> delegate;

- (void)promptToDeleteAction:(NSString *)actionName onService:(NSString *)serviceName;
- (IBAction)confirmDelete:(id)sender;
- (IBAction)cancelDelete:(id)sender;

@end
