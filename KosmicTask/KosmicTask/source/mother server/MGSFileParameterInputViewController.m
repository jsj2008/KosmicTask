//
//  MGSFileParameterInputViewController.m
//  Mother
//
//  Created by Jonathan on 07/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSFileParameterInputViewController.h"
#import "MGSFileParameterPlugin.h"
#import "NSImage+QuickLook.h"
#import "NSString_Mugginsoft.h"

// class extension
@interface MGSFileParameterInputViewController()
- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (NSArray *)allowedFileTypes;
@end

@implementation MGSFileParameterInputViewController

//@synthesize filePath = _filePath;
@synthesize filePreviewImage = _filePreviewImage;
@synthesize fileName = _fileName;
@synthesize fileSize = _fileSize;
@synthesize useFileExtensions = _useFileExtensions;
@synthesize fileExtensions = _fileExtensions;
@synthesize fileLabel = _fileLabel;

/*
 
 init  
 
 */
- (id)init
{
	self = [super initWithNibName:@"FileParameterInputView"];
	if (self) {
		self.sendAsAttachment = YES;
		self.fileLabel = @"File Content";
	}
	return self;
}




/*
 
 awake from nib
 
 */
- (void)awakeFromNib
{
	//_filePath = nil;
	
	NSImage *defaultImage = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kAlertNoteIcon)];
	
	// bind it
	[filePathTextField bind:NSValueBinding toObject:self withKeyPath:@"parameterValue" options:[NSDictionary dictionaryWithObjectsAndKeys: [[filePathTextField cell] placeholderString], NSNullPlaceholderBindingOption, nil]];
	[previewImage bind:NSValueBinding toObject:self withKeyPath:@"filePreviewImage" options:[NSDictionary dictionaryWithObjectsAndKeys: defaultImage, NSNullPlaceholderBindingOption, nil]];
	[fileNameTextField bind:NSValueBinding toObject:self withKeyPath:@"fileName" options:[NSDictionary dictionaryWithObjectsAndKeys: [[fileNameTextField cell] placeholderString], NSNullPlaceholderBindingOption, nil]];
	[fileSizeTextField bind:NSValueBinding toObject:self withKeyPath:@"fileSize" options:[NSDictionary dictionaryWithObjectsAndKeys: [[fileSizeTextField cell] placeholderString], NSNullPlaceholderBindingOption, nil]];
	
	[[filePathTextField cell] setLineBreakMode:NSLineBreakByTruncatingTail];
	[[fileNameTextField cell] setLineBreakMode:NSLineBreakByTruncatingTail];
	[[fileSizeTextField cell] setLineBreakMode:NSLineBreakByTruncatingTail];
	[[fileTypesTextField cell] setLineBreakMode:NSLineBreakByTruncatingTail];
	
	// this will send viewDidLoad to delegate
	[super awakeFromNib];
}

/*
 
 initialise from plist
 
 */
- (void)initialiseFromPlist
{
	self.useFileExtensions = [[self.plist objectForKey:MGSKeyUseFileExtensions withDefault:[NSNumber numberWithBool:NSOffState]] boolValue];
	self.fileExtensions = [self.plist objectForKey:MGSKeyFileExtensions withDefault:@""];
	self.parameterValue = [self.plist objectForKey:MGSKeyFilePath withDefault:@""];
	
	self.label = NSLocalizedString(@"Input is required", @"label text");
	
	NSString *allowedFileTypes = self.fileExtensions;
	if ([allowedFileTypes length] == 0 || !self.useFileExtensions) {
		allowedFileTypes = NSLocalizedString(@"all", @"all file types allowed");
	}
	NSString *fileTypes = [NSString stringWithFormat:@"%@ - allowed file types: %@", self.fileLabel, allowedFileTypes];
	[fileTypesTextField setStringValue: fileTypes];
}

/*
 
 - selectFile:
 
 http://developer.apple.com/mac/library/documentation/cocoa/conceptual/AppFileMgmt/Tasks/UsingAnOpenPanel.html
 
 */
- (IBAction)selectFile:(id)sender
{
	#pragma unused(sender)
	
	NSOpenPanel *op = [NSOpenPanel openPanel];
	
	// configure panel
	[op setCanChooseDirectories:NO];
	[op setCanChooseFiles:YES];
	[op setAllowsMultipleSelection:NO];
	[op setDelegate:self];
	
	// set file types if required
	NSArray *fileTypes = [self allowedFileTypes];
	
	[op setTitle:NSLocalizedString(@"Select file", @"Parameter file selection prompt")];
	[op setPrompt:NSLocalizedString(@"Select", @"Parameter file select button text")];
	
	
	/* display the NSOpenPanel */
	[op beginSheetForDirectory:[op directory] 
						  file:nil 
						 types: fileTypes
				modalForWindow:[[self view] window] 
				 modalDelegate:self 
				didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) 
				   contextInfo:nil];
}

/*
 
 - allowedFileTypes
 
 */
- (NSArray *)allowedFileTypes
{
	// set file types if required
	BOOL useExtensions = self.useFileExtensions;
	NSArray *fileTypes = nil;
	if ([self.fileExtensions length] == 0) {
		useExtensions = NO;
	}
	
	if (useExtensions) {
		
		// form separator character set
		NSMutableCharacterSet *charSet = [NSMutableCharacterSet punctuationCharacterSet];
		[charSet formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
		// get array of file extensions
		fileTypes = [self.fileExtensions componentsSeparatedByCharactersInSet:charSet];
	}
	
	return fileTypes;
}
/*
 
 open sheet did end
 
 */
- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
	#pragma unused(contextInfo)
	
	// hide the sheet
	[sheet orderOut:self];
	
	// check for cancel
	if (NSCancelButton == returnCode) {
		return;
	}
	
	// get filename
	if (0 == [[sheet filenames] count]) return;
	self.parameterValue = [[sheet filenames] objectAtIndex:0];
}



/*
 
 set parameter value
 
 */
- (void)setParameterValue:(NSString *)aPath
{
    if ([self validateParameterValue:aPath]) {
        
        // _parameterValue is private
        [super setParameterValue:aPath];
        
        // set image preview for file path
        if (aPath) {
            
            // display non image files as icons.
            // using the icon format for image types makes it more difficult to determine what is part of the image
            // and what isn't
            BOOL displayAsIcon = [NSImage isImageFile:aPath] ? NO : YES;
            NSString *fileInfo = @"";
            
            // file may not exist if say restoring parameters from history and file has been deleted
            if ([[NSFileManager defaultManager] fileExistsAtPath:aPath]) {
                self.filePreviewImage = [NSImage imageWithPreviewOfFileAtPath:aPath ofSize:[previewImage frame].size asIcon:displayAsIcon];
                self.fileName = [aPath lastPathComponent];
                
                // file attributes
                NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:aPath error:NULL];
                
                // file size string
                fileInfo = NSLocalizedString(@"Size: %@ Last modified: %@", @"File info format string below preview image");
                NSString *fileSize = [NSString mgs_stringFromFileSize:[[attrs objectForKey:NSFileSize] unsignedLongLongValue]];

                // date
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
                [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
                NSString *fileDate = [dateFormatter stringFromDate:[attrs objectForKey:NSFileModificationDate]];
                
                // set it
                fileInfo = [NSString stringWithFormat:fileInfo, fileSize, fileDate];
                
            } else {
                self.filePreviewImage = nil;
                self.fileName = [aPath lastPathComponent];
                fileInfo = NSLocalizedString(@"File not found.", @"File not found - file info format string below preview image");
            }
            self.fileSize = fileInfo;

        } else {
            self.filePreviewImage = nil;
            self.fileName = nil;
            self.fileSize = nil;
        }
    }
}

/*
 
 - validateParameterValue:
 
 */
- (BOOL)validateParameterValue:(id)newValue
{
#pragma unused(newValue)
    
    BOOL isValid = NO;
    
    if (!newValue) {
        isValid = YES;
    } else if ([newValue isKindOfClass:[NSString class]]) {
        
        // check file exists
        if ([[NSFileManager defaultManager] fileExistsAtPath:newValue]) {
            
            // check for matching extension            
            NSArray *extensions = self.allowedFileTypes;
            if (!extensions || [extensions count] == 0) {
                isValid = YES;
            } else {
                NSString *fileExtension = [(NSString *)newValue pathExtension];
                for (NSString *extension in extensions) {
                    if ([extension compare:fileExtension options:NSCaseInsensitiveSearch] == NSOrderedSame) {
                        isValid = YES;
                        break;
                    }
                }
                
            }
            
        } else {
            self.filePreviewImage = nil;
            self.fileName = [newValue lastPathComponent];
            self.fileSize = NSLocalizedString(@"File not found.", @"File not found - file info format string below preview image");
        }
    }
    
    return isValid;
}
/*
 
 show finder quick look
 
 */
- (IBAction)showFinderQuickLook:(id)sender
{
	#pragma unused(sender)
	
	[NSImage showFinderQuickLook:self.parameterValue];
}

/*
 
 can drag height override
 
 */
- (BOOL)canDragHeight
{
	return YES;
}

/*
 
 is valid
 
 */
- (BOOL)isValid
{
	// parameter value must be defined
	if (!self.parameterValue) {
		self.validationString = NSLocalizedString(@"Please select a file.", @"Validation string - no file selected");
		return NO;
	}

	// file must exist
	if (![[NSFileManager defaultManager] fileExistsAtPath:self.parameterValue]) {
		NSString *fmt = NSLocalizedString(@"File %@ does not exist. Please select another file.", @"Validation string - selected file does not exist");
		self.validationString = [NSString stringWithFormat:fmt, self.parameterValue];
		
		return NO;
	}
	
	return YES;
}
@end
