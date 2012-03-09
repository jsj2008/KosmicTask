//
//  MGSBrowserImage.h
//  Mother
//
//  Created by Jonathan on 30/08/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

@interface MGSBrowserImage : NSObject {
	NSString *_imageRepresentationType;
	NSString *_imageRepresentation;
	NSString *_imageUID;
	NSUInteger _imageVersion;
	BOOL _isSelectable;
	NSString *_imageTitle;
	NSString *_imageSubtitle;
	BOOL _permitFileRemoval;
	NSString *_filePath;
    BOOL _disposed;
}

// implement the IKImageBrowserItem informal protocol
@property (copy) NSString *imageRepresentationType;
@property (copy) NSString * imageRepresentation;
@property (copy) NSString *imageUID;
@property NSUInteger imageVersion;
@property BOOL isSelectable;
@property (copy) NSString *imageTitle;
@property (copy) NSString *imageSubtitle;	
@property (readonly) NSString *filePath;

- (void)dispose;
//- (void)setNSImageRepresentation:(NSImage *)image;
@end
