//
//  MGSImageManager.m
//  Mother
//
//  Created by Jonathan on 22/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSImageManager.h"

// see NSImage for names image constants
static MGSImageManager *_sharedManager = nil;
/*
 
 Among the new named images available on Leopard, I see:
 
 NSImageNameFolderBurnable
 NSImageNameFolderSmart
 
 I don't see an image name for a regular, unadorned folder. Have I  
 overlooked it?
 
 If you don't find anything better, the poor man's solution is - 
 [NSWorkspace iconForFile:].  If necessary, you can even name that  
 image with -[NSImage setName:] so you'll be able to refer to it from  
 nibs.  It won't appear in IB, but if you register the name early  
 enough in application startup, it will work at runtime.
 
 
 On Leopard, you can now create an NSImage from a Carbon IconRef
 
 Icons.h defines a whole heap of additional icons that you can then get  
 to. Something like this:
 
 IconRef carbonIcon;
 
 NSImage* folderImage = nil;
 OSStatus err = GetIconRef(kOnSystemDisk, kSystemIconsCreator,  
 kGenericFolderIcon, &carbonIcon);
 if (!err)
 {
 folderImage = [[NSImage alloc] initWithIconRef:carbonIcon];
 ReleaseIconRef(carbonIcon);
 }
 
 Matt Gough 
 
 or:
 
 NSImage *folderImage = [[[NSWorkspace sharedWorkspace]  
 iconForFileType:NSFileTypeForHFSTypeCode(kGenericFolderIcon)];
 kAFPServerIcon
 */

/*resize
 NSImage *image1 = [NSImage imageNamed:NSImageNameComputer];
 NSImage *image2 = [NSImage imageNamed:@"Warning"];
 
 NSImage *newImage = [[NSImage alloc] initWithSize:[image1 size]];
 
 [newImage lockFocus];
 [image1 compositeToPoint:NSMakePoint(0,0) operation:NSCompositeSourceOver];
 [image2 compositeToPoint:NSMakePoint(0,0) operation:NSCompositeSourceOver];
 [newImage unlockFocus];
 
 return newImage;*/

/*
 JM 23-02-08
 Note that the following is output to the console:
 
 Mother(3038,0xb0157000) malloc: free_garbage: garbage ptr = 0x10f9f30, has non-zero refcount = 1
 Mother(3038,0xb0157000) malloc: free_garbage: garbage ptr = 0x10fdb10, has non-zero refcount = 1
 Mother(3038,0xb0157000) malloc: free_garbage: garbage ptr = 0x121b480, has non-zero refcount = 1
 Mother(3038,0xb0157000) malloc: free_garbage: garbage ptr = 0x121bff0, has non-zero refcount = 1
 Mother(3038,0xb0157000) malloc: free_garbage: garbage ptr = 0x122d1b0, has non-zero refcount = 1
 Mother(3038,0xb0157000) malloc: free_garbage: garbage ptr = 0x1230c50, has non-zero refcount = 1
 Mother(3038,0xb0157000) malloc: free_garbage: garbage ptr = 0x1239c20, has non-zero refcount = 1
 Mother(3038,0xb0157000) malloc: free_garbage: garbage ptr = 0x1241e30, has non-zero refcount = 1
 Mother(3038,0xb0157000) malloc: free_garbage: garbage ptr = 0x1252f50, has non-zero refcount = 1
 
 see:
 
 http://www.cocoabuilder.com/archive/message/cocoa/2007/10/29/191658
 
 > I am currently working on my first GC-enabled application.
 
 
 Excellent!
 
 > When I start the application I get the following console output in  
 > Xcode:
 >
 > HoudahSpot2(20753,0xb0103000) malloc: free_garbage: garbage ptr =  
 > 0x105e7c0, has non-zero refcount = 1
 > HoudahSpot2(20753,0xb0103000) malloc: free_garbage: garbage ptr =  
 > 0x10696e0, has non-zero refcount = 1
 >
 > What can I do about this? How does one debug this?
 
 This happens to me when I use one of the built-in template images from
 interface builder like NSStopProgressFreestandingTemplate. If I remove
 the template image and use one of my own images, no GC errors. A radar
 was filed a few months ago.
 
 AND 
 
 This means that something somewhere had CFRetain()'d something and not  
 CFRelease()'d it before the collector determined that the something --  
 the collector is not limited to Objective-C objects -- is garbage  
 eligible for collection.  It is generally harmless.
 
 While -retain/-release/-autorelease are no-ops under GC, CFRetain()  
 and CFRelease() are not.
 
 In other words, this is a bug in the Apple supplied frameworks.    
 There is a radar tracking it and it'll be fixed.
 */


@implementation MGSImageManager

@synthesize empty;
@synthesize localHostAvailable;
@synthesize remoteHostAvailable;
@synthesize manualHostAvailable;
@synthesize localHostUnavailable;
@synthesize remoteHostUnavailable;
@synthesize manualHostUnavailable;
@synthesize localHostNotResponding;
@synthesize remoteHostNotResponding;
@synthesize manualHostNotResponding;
@synthesize folder;
@synthesize rightArrow;
@synthesize leftArrow;
@synthesize tick;
@synthesize cross; 
@synthesize clockFace;
@synthesize info;
@synthesize box;
@synthesize onlineStatusHeader;
@synthesize quickLookTemplate;
@synthesize followLinkTemplate;
@synthesize dotTemplate;
@synthesize splitDragThumb;
@synthesize splitDragThumbVert;
@synthesize publishedActionTemplate;
@synthesize partiallyPublishedTemplate;
@synthesize alertTriangle;
@synthesize locked;
@synthesize unlocked;
@synthesize lockLockedTemplate;
@synthesize lockUnlockedTemplate;
@synthesize user;
@synthesize scriptMask;
@synthesize script;
@synthesize scriptCompiled;
@synthesize scriptNotCompiled;
@synthesize redDot;
@synthesize yellowDot;
@synthesize greenDot;
@synthesize redDotLarge;
@synthesize greenDotLarge;
@synthesize pinMeTemplate;
@synthesize documentTemplate;
@synthesize defaultResource;
@synthesize scriptOutline;
@synthesize greenDotNoUser;
@synthesize redDotNoUser;
@synthesize greenDotUser;
@synthesize redCross16;
@synthesize greenTick16;

#pragma mark -
#pragma mark Class Methods

/*
 
 shared manager
 
 */
+ (id)sharedManager
{
	if (!_sharedManager) {
		_sharedManager = [[self alloc] init];
	}
	return _sharedManager;
}

/*
 
 init
 
 */
- (id)init
{
	if ((self = [super init])) {
		
		empty = [[NSImage alloc] initWithSize:NSMakeSize(2, 2)];
		folder = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericFolderIcon)];
		rightArrow = [NSImage imageNamed:@"GreenRightArrow.icns"];
		leftArrow = [NSImage imageNamed:@"GreenLeftArrow.icns"];
		tick = [NSImage imageNamed:@"GreenTick.icns"];
		alertTriangle = [NSImage imageNamed:@"AlertTriangle.icns"];
		cross = [NSImage imageNamed:@"RedCross.icns"];
		clockFace = [NSImage imageNamed:@"ClockFace.icns"];
		info = [NSImage imageNamed:@"Info.icns"];
		box = [NSImage imageNamed:@"Box.icns"];	
		
		localHostAvailable = [NSImage imageNamed:@"Home.icns"];
		remoteHostAvailable = [NSImage imageNamed:@"Computer.icns"];
		manualHostAvailable = [NSImage imageNamed:@"NetworkBall.icns"];
		
		localHostUnavailable = [NSImage imageNamed:@"HomeGrey.icns"];
		remoteHostUnavailable = [NSImage imageNamed:@"ComputerGrey.icns"];
		manualHostUnavailable = [NSImage imageNamed:@"NetworkBallGrey.icns"];
		
#pragma mark warning home not responding image to be made
		localHostNotResponding = [NSImage imageNamed:@"Home.icns"];
		remoteHostNotResponding = [NSImage imageNamed:@"ComputerShriek.icns"];
		manualHostNotResponding = [NSImage imageNamed:@"NetworkBallShriek.icns"];

		onlineStatusHeader = [NSImage imageNamed:@"OnlineStatusHeader"];
		quickLookTemplate = [NSImage imageNamed:@"NSQuickLookTemplate"];
		followLinkTemplate = [NSImage imageNamed:@"NSFollowLinkFreestandingTemplate"];
		dotTemplate = [NSImage imageNamed:@"DotHeader"];
		[dotTemplate setTemplate:YES];
		splitDragThumb = [NSImage imageNamed:@"SplitDragThumb2"];
		splitDragThumbVert = [NSImage imageNamed:@"SplitDragThumb2Vert"];
		locked = [NSImage imageNamed:@"Locked"];
		unlocked = [NSImage imageNamed:@"Unlocked"];
		lockLockedTemplate = [NSImage imageNamed:@"NSLockLockedTemplate"];
		lockUnlockedTemplate = [NSImage imageNamed:@"NSLockUnlockedTemplate"];
		user = [self smallImageCopy:[NSImage imageNamed:@"NSUser"]];
		[user setTemplate:YES]; 
		
		//lockedSystemIcon = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kLockedIcon)];	// works but poor quality image
								
		publishedActionTemplate = [NSImage imageNamed:@"Published.tif"];
		[publishedActionTemplate setTemplate:YES];	// this will trigger inversion in tableview row when selected etc - must be black + alpha image
		
		partiallyPublishedTemplate = [NSImage imageNamed:@"PartiallyPublished.tif"];
		[partiallyPublishedTemplate setTemplate:YES];
			
		script = [NSImage imageNamed:@"ScriptIcon"];
		scriptMask = [NSImage imageNamed:@"AppleScriptMask"];
		scriptCompiled = [NSImage imageNamed:@"ScriptIconGreen"];
		scriptNotCompiled = [NSImage imageNamed:@"ScriptIconRed"];
		
		redDot = [NSImage imageNamed:@"DotRed"];
		yellowDot = [NSImage imageNamed:@"DotYellow"];
		greenDot = [NSImage imageNamed:@"DotGreen"];

		redDotLarge = [NSImage imageNamed:@"OrbRed"];
		greenDotLarge = [NSImage imageNamed:@"OrbGreen"];

		pinMeTemplate = [NSImage imageNamed:@"PinMeTemplate"];
		documentTemplate = [NSImage imageNamed:@"Document16"];
		
		defaultResource = [NSImage imageNamed:@"YellowStar16"];
		
		scriptOutline = [NSImage imageNamed:@"ActionTaskTemplate.tif"];
        
        greenDotNoUser = [NSImage imageNamed:@"DotGreenNoUser.png"];
        redDotNoUser = [NSImage imageNamed:@"DotRedNoUser.png"];
        greenDotUser = [NSImage imageNamed:@"DotGreenUser.png"];
        
        redCross16 = [NSImage imageNamed:@"RedCross16.png"];
        greenTick16 = [NSImage imageNamed:@"GreenTick16.png"];
	}
	return self;
}

/*
 
 small image
 
 */
- (NSImage *)smallImage:(NSImage *)anImage 
{
	[anImage setScalesWhenResized:YES];
	[anImage setSize:NSMakeSize(16,16)];
	
	//NSImage *smallImage = [[NSImage alloc] initWithSize:NSMakeSize(16,16)];
	//[smallImage addRepresentation:[anImage];
						   
	return anImage;
}

/*
 
 small image copy
 
 */
- (NSImage *)smallImageCopy:(NSImage *)anImage 
{
	return [self copyImage:anImage newSize:NSMakeSize(16,16)];
}

/*
 
 copy image
 
 */
- (NSImage *)copyImage:(NSImage *)anImage newSize:(NSSize)size
{
	#pragma unused(size)
	
	return [self smallImage:[anImage copy]];
}

/*
 
 construct a view containing a drag thumb
 
 */
- (NSImageView *)splitDragThumbView
{
	return [self imageView:[[[MGSImageManager sharedManager] splitDragThumb] copy]];
}

/*
 
 construct a view containing an image
 
 */
- (NSImageView *)imageView:(NSImage *)image
{
	NSImageView *imageView = [[NSImageView alloc] init];
	[imageView setImageScaling:NSScaleNone];
	[imageView setImageFrameStyle:NSImageFrameNone];
	[imageView setImage:image];
	
	return imageView;
}
@end


