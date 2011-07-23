//
//  MGSFolderPathParameterInputViewController.h
//  KosmicTask
//
//  Created by Jonathan on 18/07/2011.
//  Copyright 2011 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSParameterSubInputViewController.h"

@interface MGSFolderParameterInputViewController : MGSParameterSubInputViewController <NSOpenSavePanelDelegate> {
	
	IBOutlet NSTextField *pathTextField;
	NSString *_fileLabel;
}

@property (copy) NSString *fileLabel;

- (IBAction)selectFile:(id)sender;
@end
