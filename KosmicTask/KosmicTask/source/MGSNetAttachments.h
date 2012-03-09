//
//  MGSNetAttachments.h
//  Mother
//
//  Created by Jonathan on 25/08/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSNetAttachment.h"
#import "NSObject+MGSDisposable.h"

@class MGSNetAttachment;
@class MGSTempStorage;

@interface MGSNetAttachments : NSObject <MGSNetAttachment> {
	NSMutableArray *_attachments;
	NSOperationQueue *_operationQueue;
	NSMutableArray *_attachmentPreviewImages;
	NSArrayController *_browserImagesController;
	id delegate;
	MGSTempStorage *_storageFacility;

}
@property (readonly) NSOperationQueue *operationQueue;
@property (readonly) NSMutableArray *attachmentPreviewImages;
@property (readonly) NSArrayController *browserImagesController;
@property (assign) id delegate;


+ (NSString *)defaultHeaderRepresentation;
- (MGSNetAttachment *)addAttachment:(MGSNetAttachment *)attachment;
- (MGSNetAttachment *)addAttachmentToExistingReadableFile:(NSString *)filePath;
- (MGSNetAttachment *)addAttachmentToCreatedTempFileWithRequiredLength:(unsigned long long)requiredLength;
- (NSString *)headerRepresentation;
- (NSArray *)array;
- (id)initWithHeaderRepresentation:(NSString *)headerRepresentation;
- (NSUInteger)count;
- (MGSNetAttachment *)attachmentAtIndex:(NSUInteger)index;
- (NSArray *)propertyListRepresentation;
- (void)parsePropertyListRepresentation:(NSArray *)list;
- (void)generateAttachmentPreviews;
- (unsigned long long)validatedLength;
- (unsigned long long)requiredLength;
- (MGSTempStorage *)storageFacility;
@end
