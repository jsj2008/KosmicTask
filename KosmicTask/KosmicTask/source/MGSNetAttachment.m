//
//  MGSNetAttachment.m
//  Mother
//
//  Created by Jonathan on 23/08/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSMother.h"
#import "MGSBrowserImage.h"
#import "MGSNetAttachment.h"
#import "NSString_Mugginsoft.h"
#import "MGSKosmicTask/MGSTempStorage.h"

static NSString *MGSAttachmentKeyLength = @"Length";
static NSString *MGSAttachmentKeyFileName = @"FileName";

@interface MGSNetAttachment(Private)
- (BOOL)applyFileName:(NSString *)filename;
- (void)checkForTempFilePath;
@end


@implementation MGSNetAttachment


@synthesize delegate = _delegate;
@synthesize validatedLength = _validatedLength;
@synthesize requiredLength = _requiredLength;
@synthesize filePath = _filePath;
@synthesize permitFileRemoval = _permitFileRemoval;
@synthesize tempFile = _tempFile;
@synthesize browserImage = _browserImage;
@synthesize index = _index;

/*
 
 attachment with file path
 
 */
+ (id)attachmentWithFilePath:(NSString *)filePath
{
	return [[self alloc] initWithFilePath:filePath];
}

/*
 
 - initWithStorageFacility:
 
 */
- (id)initWithStorageFacility:(MGSTempStorage *)tempStorage
{
	// if no temp storage defined then use the shared instance
	if (!tempStorage) {
		tempStorage = [MGSTempStorage sharedController];
	} 
	_tempStorage = tempStorage;
	
	// create a storage file
	NSString *filePath = [_tempStorage storageFileWithOptions:[NSDictionary dictionaryWithObjectsAndKeys:
															   @"", MGSTempFileSuffix,
															   nil]];
	if (!filePath) {
		MLog(RELEASELOG, @"Attachment could not created at temp file path %@", filePath);
		return nil;
	}
	
	MLog(DEBUGLOG, @"Temp attachment file path is: %@", filePath);
	
	// create attachment with file path
	self = [self initWithFilePath:filePath];
	if (self) {
		
	}
	
	return self;
}
/*
 
 init with file path
 
 designated initialiser
 
 */
- (id)initWithFilePath:(NSString *)filePath
{
	if (!filePath) {
		return nil;
	}
	
	if ((self = [super init])) {
		_validatedLength = 0;
		_requiredLength = 0;
		_filePath = [filePath copy];
		_readHandle = nil;
		_writeHandle = nil;
		_permitFileRemoval = NO;
		_tempFile = NO;
		_disposed = NO;
		
		// must validate
		if (![self validate]) {
			return nil;
		}
		
		[self checkForTempFilePath];
		
		MLog(DEBUGLOG, @"Attachment created: %@", [self description]);

	}
	
	return self;
}


/*
 
 + attachmentWithStorageFacility
 
 */
+ (id)attachmentWithStorageFacility:(MGSTempStorage *)tempStorage
{
	return [[self alloc] initWithStorageFacility:tempStorage];
}

/*
 
 description
 
 */
- (NSString *)description
{
	return [NSString stringWithFormat: @"Attachment path: %@ validated length:%qu requiredLength: %qu", _filePath, _validatedLength, _requiredLength];
}
	
/*
 
 init
 
 */
- (id)init
{
	return [self initWithFilePath:nil]; 
}



/*
 
 open attachment for reading
 
 */
- (BOOL)openForReading
{
	if (!_readHandle) {
		_readHandle = [NSFileHandle fileHandleForReadingAtPath:_filePath];
	}
	
	return _readHandle ? YES : NO;
}


/*
 
 open attachment for writing
 
 */
- (BOOL)openForWriting
{
	if (!_writeHandle) {
		_writeHandle = [NSFileHandle fileHandleForWritingAtPath:_filePath];
	}
	
	return _writeHandle ? YES : NO;
}

/*
 
 close for reading

 */
- (void)closeForReading
{
	if (_readHandle) {
		[_readHandle closeFile];
		_readHandle = nil;
	}
}

/*
 
 close for writing
 
 */
- (void)closeForWriting
{
	if (_writeHandle) {
		[_writeHandle closeFile];
		_writeHandle = nil;
	}
	
	// valiate the attachment to determine the actual attachment size on disk
	[self validate];
}

/*
 
 read data of length with error
 
 */
- (NSData *)readDataOfLength:(NSUInteger)length error:(MGSError **)mgsError
{
	NSData *data = nil;
	@try {
		
		if (!_readHandle) {
			return nil;
		}
		
		data = [_readHandle readDataOfLength:length];
	}
	@catch (NSException *e) {
		NSString *errorFmt = NSLocalizedString(@"Cannot read from attachment file: %@", @"Attachment file read error");
		NSString *error = [NSString stringWithFormat:errorFmt, _filePath];
		*mgsError = [MGSError frameworkCode:MGSErrorCodeAttachment reason:error];
		MLog(RELEASELOG, @"Exception: %@", e);
	}
	@finally {
		return data;
	}
}

/*
 
 read offset
 
 */
- (unsigned long long)readOffset
{
	return [_readHandle offsetInFile];
}

/*
 
 write offset
 
 */
- (unsigned long long)writeOffset
{
	return [_writeHandle offsetInFile];
}

/*
 
 write data with error
 
 */
- (BOOL)writeData:(NSData *)data error:(MGSError **)mgsError
{
	@try {
		
		if (!_writeHandle) {
			return NO;
		}
		
		[_writeHandle writeData:data];
	}
	@catch (NSException *e) {
		NSString *errorFmt = NSLocalizedString(@"Cannot write to attachment file: %@", @"Attachment file write error");
		NSString *error = [NSString stringWithFormat:errorFmt, _filePath];
		*mgsError = [MGSError frameworkCode:MGSErrorCodeAttachment reason:error];
		
		MLog(RELEASELOG, @"Exception: %@", e);
		
		return NO;
	}
	
	return YES;
}

/*
 
 validate the file path
 
 */
- (BOOL)validate
{
	_validatedLength = 0;
	
	NSFileHandle *fh = [NSFileHandle fileHandleForReadingAtPath:_filePath];
	if (!fh) {
		MLog(DEBUGLOG, @"Attachment failed validation: %@", [self description]);
		MLog(RELEASELOG, @"Attachment file %@ does not exist or cannot be read.", _filePath);
		return NO;
	}
	
	[fh closeFile];
	
	NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:_filePath error:NULL];
	NSNumber *fileSize;
	
    if ((fileSize = [attributes objectForKey:NSFileSize])) {
		_validatedLength = [fileSize unsignedLongLongValue];
    } else {
		MLog(DEBUGLOG, @"Attachment failed validation: %@", [self description]);
		MLog(RELEASELOG, @"Attachment file %@ size attribute cannot be read.", _filePath);
		return NO;
	}
	
	return YES;
}

/*
 
 dispose
 
 */
- (void)dispose
{

	if (_disposed) {
		MLog(DEBUGLOG, @"Dispose already called for attachment: %@", _filePath);
		return;
	}
	_disposed = YES;
	
	//
	// note that the same attachment may exist in the request and response messages.
	// a file is sent via the request, processed and returned via the response.
	// in this case the temp file is the same in each case.
	// so when finalization occurs one message will always be finalized first, deleting the shared temp file.
	// so better to check for existence first.
	//
	if (![[NSFileManager defaultManager] fileExistsAtPath:_filePath]) {
		
		// our temp file has already been removed
		return;
	}
	
	/*
	 
	 if file is on the temp storage path then permit its removal
	 
	 */
	if ([_filePath hasPrefix:[[MGSTempStorage sharedController] storageFacility]]) {
		_permitFileRemoval = YES;
	}
	
	if (_permitFileRemoval) {
		if ([[NSFileManager defaultManager] removeItemAtPath:_filePath error:NULL]) {
			MLog(DEBUGLOG, @"Deleted attachment file: %@", _filePath);
		} else {
			MLog(RELEASELOG, @"Could not delete attachment file: %@", _filePath);
		}
	} else {
		MLog(DEBUGLOG, @"Deletion not requested for attachment file: %@", _filePath);
	}
}

/*
 
 dictionary representation
 
 */ 
- (NSDictionary *)dictionaryRepresentation
{
	return [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithUnsignedLongLong:_validatedLength], MGSAttachmentKeyLength,
												[self lastPathComponent], MGSAttachmentKeyFileName , nil];
}

/*
 
 parse dictionary representation
 
 */
- (void)parseDictionaryRepresentation:(NSDictionary *)dict
{
	// look in dict for original filename of attachment
	NSString *fileName = [dict objectForKey:MGSAttachmentKeyFileName];
	if (fileName) {
		[self applyFileName:fileName];
	}
}

/*
 
 last path component
 
 */
+ (NSString *)lastPathComponent:(NSString *)path
{
	NSString *lastPathComponent = [path lastPathComponent];
	
	// if our path contains a temp file then our true last component lies
	// after the temp file suffix
	
	//if (_tempFile) {
		NSArray *components = [lastPathComponent componentsSeparatedByString:[MGSKosmicTempFileNamePrefix stringByAppendingString:@"."]];
		lastPathComponent = [components count] >= 2 ? [components objectAtIndex:1] : lastPathComponent;
	//}
	
	return lastPathComponent;
}
/*
 
 last path component
 
 */
- (NSString *)lastPathComponent
{
	return [[self class] lastPathComponent: _filePath];
}

/*
 
 generate file preview image
 
 may be called in a separate thread
 
 */
- (void)generateFilePreview
{
	// get image representation
	self.browserImage.imageRepresentation = self.filePath;
	
	// set image attributes
	self.browserImage.imageTitle = [self lastPathComponent];
	
	self.browserImage.imageSubtitle = [self validatedTitle];
	
	[_delegate performSelectorOnMainThread:@selector(attachmentPreviewAvailable:) withObject:self waitUntilDone:NO];
}

/*
 
 validated title
 
 */

- (NSString *)validatedTitle
{
	NSString *fileSizeString = [NSString mgs_stringFromFileSize:self.validatedLength];
	
	return [NSString stringWithFormat:NSLocalizedString(@"file %u, %@", @"Attachment title"), self.index+1, fileSizeString];
}
/*
 
 browser image
 
 */
- (MGSBrowserImage *)browserImage
{
	@synchronized (self) {
		
		// lazy allocation
		if (!_browserImage) {
			_browserImage = [MGSBrowserImage new];
		}
		
	}
	
	return _browserImage;
}
@end


@implementation MGSNetAttachment(Private)

/*
 
 rename file
 
 */
- (BOOL)applyFileName:(NSString *)filename
{

	// rename the temp file so that it ends with name of original file.
	// this should succeed as the temp file name itself is unqiue
	NSString *attachmentPath = self.filePath;
	NSString *newAttachmentPath = nil;
	
	// If tempStorage defined and unique file names are not a requirement then try
	// and rename file to use filename only. If this fails we use the default implementation
	// and retain the unique file prefix
	if (_tempStorage && ![_tempStorage alwaysGenerateUniqueFilenames]) {
		newAttachmentPath = [[attachmentPath stringByDeletingLastPathComponent]
							 stringByAppendingPathComponent:filename];
		if (![[NSFileManager defaultManager] moveItemAtPath:attachmentPath toPath:newAttachmentPath error:NULL]) {
			newAttachmentPath = nil;
		}
	}
	
	if (!newAttachmentPath) {
		
		/*
		 we have a name collision.
		 
		 TODO: a better solution might be creat a unique sub directory and copy the file into it.
		 In that way the original file name could be preserved.
		 
		 */
		newAttachmentPath = [NSString stringWithFormat:@"%@.%@", attachmentPath, filename];
		if (![[NSFileManager defaultManager] moveItemAtPath:attachmentPath toPath:newAttachmentPath error:NULL]) {
			NSString *error = NSLocalizedString(@"Cannot create parameter attachment file", @"Returned by server when cannot rename temp attachment file");
			MLog(RELEASELOG, @"%@ : %@", error, newAttachmentPath);	
			
			return NO;
		}
		
	}

	_filePath = newAttachmentPath;

	return YES;
}

/*
 
 check for temp file path
 
 */
- (void)checkForTempFilePath
{
	// if file path indicates that the file is a mother created temp file
	// then the file will be flagged for removal on finalize
	//BOOL isTempFile = [_filePath mgs_isTempFilePathContaining:MGSAttachmentTempFileSuffix];

	BOOL isTempFile = [_filePath hasPrefix:[[MGSTempStorage sharedController] storageFacility]];
	
	if (isTempFile) {
		MLog(DEBUGLOG, @"Attachment temp file WILL be removed on finalization: %@", _filePath);
	} else {
		MLog(DEBUGLOG, @"Attachment user file will NOT  be removed on finalization: %@", _filePath);
	}
	
	_permitFileRemoval = isTempFile;
	_tempFile = isTempFile;
}
@end
