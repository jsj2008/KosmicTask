//
//  MGSBrowserImage.m
//  Mother
//
//  Created by Jonathan on 30/08/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSBrowserImage.h"
#import "NSString_Mugginsoft.h"
#import "NSImage+QuickLook.h"

@implementation MGSBrowserImage

@synthesize imageRepresentationType = _imageRepresentationType;
@synthesize imageRepresentation = _imageRepresentation;
@synthesize imageUID = _imageUID;
@synthesize imageVersion = _imageVersion;
@synthesize isSelectable = _isSelectable;
@synthesize imageTitle = _imageTitle;
@synthesize imageSubtitle = _imageSubtitle;
@synthesize filePath = _filePath;

/*
 
 init
 
 */
- (id)init
{
	if ((self = [super init])) {
		_imageUID = [NSString mgs_stringWithNewUUID];
		_imageTitle = NSLocalizedString(@"untitled", @"default name for image browser image");
		_imageSubtitle = @"---";
		self.imageRepresentationType = IKImageBrowserPathRepresentationType;
		_permitFileRemoval = NO;
		_isSelectable = YES;
	}
	return self;
}

/*

 set image representation
 
 if the file is an image file support by the image browser then the path to the file is retained.
 if not then a preview image is generated and the path to the preview is retained.
  
 */
- (void)setImageRepresentation:(NSString *)path
{
	// retain path
	_filePath = path;
	
	// check if file type is image
	if (![NSImage isImageFile:path]) {

		// note that the browser seems to be able to generate its own preview images.
		// these are not as detailed however as the quicklook generated ones
		NSImage *image = [NSImage imageWithPreviewOfFileAtPath:path ofSize:NSMakeSize(300, 300) asIcon:YES];
		
		// get a temp file path
		NSString *newpath = [NSString mgs_stringWithCreatedTempFilePath];
		[[NSFileManager defaultManager] removeItemAtPath:newpath error:NULL];

		if (![[image TIFFRepresentation] writeToFile:newpath atomically:YES]) {
			MLog(DEBUGLOG, @"could not save preview: %@", newpath);
		}
		
		_permitFileRemoval = YES;
		path = newpath;
	}
	
	// set the image representation
	_imageRepresentation = path;
}

#pragma mark -
#pragma mark memory management
/*
 
 -finalize
 
 */
- (void)finalize
{
    if (!_disposed) {
        MLogInfo(@"MGSBrowserImage. MEMORY LEAK. Dispose has not been called.");
    }
    
    [super finalize];
}

#pragma mark -
#pragma mark resource management
/*
 
 - dispose
 
 */
- (void)dispose
{
    if (_disposed) {
        MLogInfo(@"Dispose has already been called");
        return;
    }
    
    _disposed = YES;
    
	if (_permitFileRemoval) {
		if ([[NSFileManager defaultManager] fileExistsAtPath:_imageRepresentation]) {
			if (![[NSFileManager defaultManager] removeItemAtPath:_imageRepresentation error:NULL]) {
				MLog(DEBUGLOG, @"could not delete preview: %@", _imageRepresentation);
			} else {
				MLog(DEBUGLOG, @"deleted preview: %@", _imageRepresentation);
			}
		}
	} else {
		MLog(DEBUGLOG, @"no preview deletion required: %@", _imageRepresentation);
	}
}
@end
