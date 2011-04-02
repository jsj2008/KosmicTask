//
//  MGSFileParameterEditViewController.h
//  Mother
//
//  Created by Jonathan on 06/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSParameterSubEditViewController.h"

@interface MGSFileParameterEditViewController : MGSParameterSubEditViewController <NSOpenSavePanelDelegate> {
	IBOutlet NSTextField *fileExtensionsTextField;
	IBOutlet NSButton *useRequiredFileExtensionCheckbox;
	BOOL _useFileExtensions;
	NSString *_fileExtensions;
	NSString *_filePath;
	IBOutlet NSTextField *fileNameTextField;
}

@property BOOL useFileExtensions;
@property (copy) NSString *fileExtensions;
@property (copy) NSString *filePath;

- (IBAction)selectFile:(id)sender;

@end
