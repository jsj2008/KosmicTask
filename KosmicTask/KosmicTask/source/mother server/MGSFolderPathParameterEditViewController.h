//
//  MGSFolderPathParameterEditViewController.h
//  KosmicTask
//
//  Created by Jonathan on 18/07/2011.
//  Copyright 2011 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSParameterSubEditViewController.h"

@interface MGSFolderPathParameterEditViewController : MGSParameterSubEditViewController <NSOpenSavePanelDelegate> {
	NSString *_folderPath;
	IBOutlet NSTextField *pathTextField;
}

@property (copy) NSString *folderPath;

- (IBAction)selectFile:(id)sender;

@end
