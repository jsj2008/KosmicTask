//
//  MGSNetAttachment.h
//  Mother
//
//  Created by Jonathan on 23/08/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSDisposableObject.h"

@class MGSError;
@class MGSNetAttachment;
@class MGSBrowserImage;
@class MGSTempStorage;

@protocol MGSNetAttachment <NSObject>
@required
- (void)attachmentPreviewAvailable:(MGSNetAttachment *)sender;
@end

@interface MGSNetAttachment : MGSDisposableObject {
	unsigned long long _validatedLength;	// validated length of the file
	unsigned long long _requiredLength;		// required length of the file
	NSString *_filePath;  
	NSFileHandle *_readHandle;
	NSFileHandle *_writeHandle;
	BOOL _permitFileRemoval;
	BOOL _tempFile;
	MGSBrowserImage *_browserImage;
	id __strong _delegate;
	NSUInteger _index;
	MGSTempStorage *_tempStorage;
}
@property (strong) id delegate;

@property (readonly) unsigned long long validatedLength;
@property unsigned long long requiredLength;
@property NSUInteger index;
@property (readonly) NSString *filePath; 
@property (readonly) BOOL permitFileRemoval;
@property (readonly) BOOL tempFile;
@property  MGSBrowserImage *browserImage;

- (id)initWithStorageFacility:(MGSTempStorage *)tempStorage;
+ (id)attachmentWithFilePath:(NSString *)filePath;
+ (id)attachmentWithStorageFacility:(MGSTempStorage *)storageFacility;
+ (NSString *)lastPathComponent:(NSString *)path;

- (id)initWithFilePath:(NSString *)filePath;
- (BOOL)openForReading;
- (void)closeForReading;
- (BOOL)openForWriting;
- (void)closeForWriting;
- (NSData *)readDataOfLength:(NSUInteger)length error:(MGSError **)error;
- (BOOL)validate;
- (unsigned long long)readOffset;
- (BOOL)writeData:(NSData *)data error:(MGSError **)mgsError;
- (unsigned long long)writeOffset;
- (void)dispose;
- (NSDictionary *)dictionaryRepresentation;
- (void)parseDictionaryRepresentation:(NSDictionary *)dict;
- (NSString *)lastPathComponent;
- (void)generateFilePreview;
- (NSString *)validatedTitle;
@end
