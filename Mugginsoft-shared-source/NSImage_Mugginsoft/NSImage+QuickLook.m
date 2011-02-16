//
//  NSImage+QuickLook.m
//  QuickLookTest
//
//  Created by Matt Gemmell on 29/10/2007.
//

#import "NSImage+QuickLook.h"
#import <QuickLook/QuickLook.h> // Remember to import the QuickLook framework into your project!

@implementation NSImage (QuickLook)

/*
 
 image with preview of file at path 
 
 */
+ (NSImage *)imageWithPreviewOfFileAtPath:(NSString *)path ofSize:(NSSize)size asIcon:(BOOL)icon
{
	@try {
		// check we have something to work with
		if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
			NSLog(@"No file to preview at %@", path);
			return nil;
		}
		
		NSURL *fileURL = [NSURL fileURLWithPath:path];
		if (!path || !fileURL) {
			NSLog(@"Invalid file path for preview");
			return nil;
		}
		
		NSDictionary *dict = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:icon] 
														 forKey:(NSString *)kQLThumbnailOptionIconModeKey];
		//NSDictionary *dict = nil;
		CGImageRef ref = QLThumbnailImageCreate(kCFAllocatorDefault, 
												(CFURLRef)fileURL, 
												CGSizeMake(size.width, size.height),
												(CFDictionaryRef)dict);
		
		if (ref != NULL) {
			// Take advantage of NSBitmapImageRep's -initWithCGImage: initializer, new in Leopard,
			// which is a lot more efficient than copying pixel data into a brand new NSImage.
			// Thanks to Troy Stephens @ Apple for pointing this new method out to me.
			NSBitmapImageRep *bitmapImageRep = [[NSBitmapImageRep alloc] initWithCGImage:ref];
			NSImage *newImage = nil;
			if (bitmapImageRep) {
				newImage = [[NSImage alloc] initWithSize:[bitmapImageRep size]];
				[newImage addRepresentation:bitmapImageRep];
				[bitmapImageRep release];
				
				if (newImage) {
					return [newImage autorelease];
				}
			}
			CFRelease(ref);
		} else {
			// If we couldn't get a Quick Look preview, fall back on the file's Finder icon.
			NSImage *finderIcon = [[NSWorkspace sharedWorkspace] iconForFile:path];
			if (finderIcon) {
				// if want to change the icon size then it will have to be scaled proportionally.
				// simply setting to size may distort the apsect ratio
				//[finderIcon setSize:size];
			}
			return finderIcon;
		}
    }
	@catch (NSException *e) {
		NSLog(@"Exception generating quicklook preview : %@", e);
	}
	
    return nil;
}

/*
 
 show finder quick look
 
 */
+ (void)showFinderQuickLook:(NSString *)filePath
{
	@try{
		NSArray *arguments = [NSArray arrayWithObjects: @"-p", filePath,  nil];
		NSTask *task = [[NSTask alloc] init];
		
		
		[task setArguments:arguments];
		[task setLaunchPath:@"/usr/bin/qlmanage"];
		[task setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];	// qlmanage is a dev tool and generates console output
		[task setStandardError:[NSFileHandle fileHandleWithNullDevice]];	// qlmanage is a dev tool and generates console output
		
		[task launch];
	}@catch (NSException *e)
	{
		NSLog(@"Exception starting QuickLook: %@", e);
	}
}

// -------------------------------------------------------------------------
//	isImageFile:filePath
//
//	This utility method indicates if the file located at 'filePath' is
//	an image file based on the UTI. It relies on the ImageIO framework for the
//	supported type identifiers.
//
// -------------------------------------------------------------------------
+ (BOOL)isImageFile:(NSString*)filePath
{
	BOOL				isImageFile = NO;
	LSItemInfoRecord	info;
	CFStringRef			uti = NULL;
	
	CFURLRef url = CFURLCreateWithFileSystemPath(NULL, (CFStringRef)filePath, kCFURLPOSIXPathStyle, FALSE);
	
	if (LSCopyItemInfoForURL(url, kLSRequestExtension | kLSRequestTypeCreator, &info) == noErr)
	{
		// Obtain the UTI using the file information.
		
		// If there is a file extension, get the UTI.
		if (info.extension != NULL)
		{
			uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, info.extension, kUTTypeData);
			CFRelease(info.extension);
		}
		
		// No UTI yet
		if (uti == NULL)
		{
			// If there is an OSType, get the UTI.
			CFStringRef typeString = UTCreateStringForOSType(info.filetype);
			if ( typeString != NULL)
			{
				uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassOSType, typeString, kUTTypeData);
				CFRelease(typeString);
			}
		}
		
		// Verify that this is a file that the ImageIO framework supports.
		if (uti != NULL)
		{
			CFArrayRef  supportedTypes = CGImageSourceCopyTypeIdentifiers();
			CFIndex		i, typeCount = CFArrayGetCount(supportedTypes);
			
			for (i = 0; i < typeCount; i++)
			{
				if (UTTypeConformsTo(uti, (CFStringRef)CFArrayGetValueAtIndex(supportedTypes, i)))
				{
					isImageFile = YES;
					break;
				}
			}
		}
	}
	
	return isImageFile;
}
@end
