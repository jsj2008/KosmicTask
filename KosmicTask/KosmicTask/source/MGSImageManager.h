//
//  MGSImageManager.h
//  Mother
//
//  Created by Jonathan on 22/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MGSImageManager : NSObject {
	NSImage *empty;
	
	NSImage *localHostAvailable;	// local host 
	NSImage *remoteHostAvailable;	// host identified by bonjour
	NSImage *manualHostAvailable;	// host identified manually

	NSImage *localHostUnavailable;
	NSImage *remoteHostUnavailable;
	NSImage *manualHostUnavailable;
	
	NSImage *localHostNotResponding;
	NSImage *remoteHostNotResponding;
	NSImage *manualHostNotResponding;
	
	NSImage *folder;
	NSImage *rightArrow;
	NSImage *leftArrow;
	NSImage *tick;
	NSImage *cross; 
	NSImage *clockFace;
	NSImage *info;
	NSImage *box;
	NSImage *onlineStatusHeader;
	NSImage *quickLookTemplate;
	NSImage *followLinkTemplate;
	NSImage *dotTemplate;
	NSImage *splitDragThumb;
	NSImage *splitDragThumbVert;
	NSImage *publishedActionTemplate;
	NSImage *partiallyPublishedTemplate;
	NSImage *alertTriangle;
	NSImage *locked;
	NSImage *unlocked;
	NSImage *lockLockedTemplate;
	NSImage *lockUnlockedTemplate;
	NSImage *user;
	NSImage *script;
	NSImage *scriptMask;
	NSImage *scriptCompiled;
	NSImage *scriptNotCompiled;
	NSImage *redDot;
	NSImage *yellowDot;
	NSImage *greenDot;
	NSImage *redDotLarge;
	NSImage *greenDotLarge;
	NSImage *pinMeTemplate;
	NSImage *documentTemplate;
	NSImage *defaultResource;
	NSImage *scriptOutline;
    NSImage *greenDotNoUser;
    NSImage *redDotNoUser;
    NSImage *greenDotUser;
    NSImage *redCross16;
    NSImage *greenTick16;
}

+ (id)sharedManager;

- (NSImage *)smallImage:(NSImage *)anImage;
- (NSImage *)copyImage:(NSImage *)anImage newSize:(NSSize)size;
- (NSImage *)smallImageCopy:(NSImage *)anImage;
- (NSImageView *)splitDragThumbView;
- (NSImageView *)imageView:(NSImage *)image;

@property (readonly) NSImage *empty;
@property (readonly) NSImage *localHostAvailable;
@property (readonly) NSImage *remoteHostAvailable;
@property (readonly) NSImage *manualHostAvailable;
@property (readonly) NSImage *localHostUnavailable;
@property (readonly) NSImage *remoteHostUnavailable;
@property (readonly) NSImage *manualHostUnavailable;
@property (readonly) NSImage *localHostNotResponding;
@property (readonly) NSImage *remoteHostNotResponding;
@property (readonly) NSImage *manualHostNotResponding;
@property (readonly) NSImage *folder;
@property (readonly) NSImage *rightArrow;
@property (readonly) NSImage *leftArrow;
@property (readonly) NSImage *tick;
@property (readonly) NSImage *cross; 
@property (readonly) NSImage *clockFace;
@property (readonly) NSImage *info;
@property (readonly) NSImage *box;
@property (readonly) NSImage *onlineStatusHeader;
@property (readonly) NSImage *quickLookTemplate;
@property (readonly) NSImage *followLinkTemplate;
@property (readonly) NSImage *dotTemplate;
@property (readonly) NSImage *splitDragThumb;
@property (readonly) NSImage *splitDragThumbVert;
@property (readonly) NSImage *publishedActionTemplate;
@property (readonly) NSImage *partiallyPublishedTemplate;
@property (readonly) NSImage *alertTriangle;
@property (readonly) NSImage *locked;
@property (readonly) NSImage *unlocked;
@property (readonly) NSImage *lockLockedTemplate;
@property (readonly) NSImage *lockUnlockedTemplate;
@property (readonly) NSImage *user;
@property (readonly) NSImage *script;
@property (readonly) NSImage *scriptMask;
@property (readonly) NSImage *scriptCompiled;
@property (readonly) NSImage *scriptNotCompiled;
@property (readonly) NSImage *redDot;
@property (readonly) NSImage *yellowDot;
@property (readonly) NSImage *greenDot;
@property (readonly) NSImage *redDotLarge;
@property (readonly) NSImage *greenDotLarge;
@property (readonly) NSImage *pinMeTemplate;
@property (readonly) NSImage *documentTemplate;
@property (readonly) NSImage *defaultResource;
@property (readonly) NSImage *scriptOutline;
@property (readonly) NSImage *greenDotNoUser;
@property (readonly) NSImage *redDotNoUser;
@property (readonly) NSImage *greenDotUser;
@property (readonly) NSImage *redCross16;
@property (readonly) NSImage *greenTick16;
@end
