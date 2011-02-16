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
	id _delegate;
	NSWindow *_modalForWindow;
}

@property NSWindow *modalForWindow;
@property id <MGSActionDeleteWindowControllerDelegate> delegate;

- (void)promptToDeleteAction:(NSString *)actionName onService:(NSString *)serviceName;
- (IBAction)confirmDelete:(id)sender;
- (IBAction)cancelDelete:(id)sender;

@end
