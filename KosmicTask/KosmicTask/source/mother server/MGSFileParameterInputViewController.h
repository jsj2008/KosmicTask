//
//  MGSFileParameterInputViewController.h
//  Mother
//
//  Created by Jonathan on 07/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSParameterSubInputViewController.h"

@interface MGSFileParameterInputViewController : MGSParameterSubInputViewController <NSOpenSavePanelDelegate> {

	IBOutlet NSTextField *filePathTextField;
	IBOutlet NSImageView *previewImage;
	NSImage *_filePreviewImage;
	IBOutlet NSTextField *fileNameTextField;
	IBOutlet NSTextField *fileSizeTextField;
	IBOutlet NSTextField *fileTypesTextField;
	NSString *_fileName;
	NSString *_fileSize;
	NSString *_fileLabel;
	
	BOOL _useFileExtensions;
	NSString *_fileExtensions;
	
	//NSString *_filePath;
}

//@property (copy) NSString *filePath;
@property (copy) NSImage *filePreviewImage;
@property (copy) NSString *fileName;
@property (copy) NSString *fileSize;
@property BOOL useFileExtensions;
@property (copy) NSString *fileExtensions;
@property (copy) NSString *fileLabel;

- (IBAction)selectFile:(id)sender;
- (IBAction)showFinderQuickLook:(id)sender;

@end
