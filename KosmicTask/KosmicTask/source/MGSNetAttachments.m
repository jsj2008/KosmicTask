//
//  MGSNetAttachments.m
//  Mother
//
//  Created by Jonathan on 25/08/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
//#import <limits.h>
#import "MGSMother.h"
#import "MGSNetAttachments.h"
#import "NSString_Mugginsoft.h"
#import "NSScanner_Mugginsoft.h"
#import "MGSTempStorage.h"

static NSString *MGSAttachmentSeparator = @";";


@interface MGSNetAttachments(Private)
- (BOOL)scanHeaderRepresentation:(NSString *)rep;
@end

@implementation MGSNetAttachments

@synthesize operationQueue = _operationQueue;
@synthesize attachmentPreviewImages = _attachmentPreviewImages;
@synthesize browserImagesController = _browserImagesController;
@synthesize delegate;

/*
 
 default header representation
 
 */
+ (NSString *)defaultHeaderRepresentation
{
	return [NSString stringWithFormat:@"%lu", 0];	
}

/*
 
 init
 
 */
- (id) init
{
	return [self initWithHeaderRepresentation:nil];
}

/*
 
 init with header representation
 
 */
- (id)initWithHeaderRepresentation:(NSString *)headerRepresentation
{
	if ((self = [super init])) {
			
		_attachments = [NSMutableArray arrayWithCapacity:1];
		
		_browserImagesController = [NSArrayController new];
		//[_browserImagesController bind:NSContentArrayBinding toObject:self withKeyPath:@"attachmentPreviewImages" options:nil];
		[_browserImagesController setContent:_attachmentPreviewImages];
		
		if (headerRepresentation) {
			if (![self scanHeaderRepresentation:headerRepresentation]) {
				return nil;
			}
		}
	}
	
	return self;
}

/*
 
 - storageFacility
 
 */
- (MGSTempStorage *)storageFacility
{
	if (!_storageFacility) {
		_storageFacility = [[MGSTempStorage alloc] initStorageFacility];
	}
	
	return _storageFacility;
}

/*
 
 add attachment to existing file path
 
 */
- (MGSNetAttachment *)addAttachmentToExistingReadableFile:(NSString *)filePath
{
	// file path must exist and be readable
	MGSNetAttachment *attachment = [MGSNetAttachment attachmentWithFilePath:filePath];
	if (!attachment) {
		MLog(DEBUGLOG, @"Attachment could not created for: %@", filePath);
		return nil;
	}

	return [self addAttachment:attachment];
}

/*
 
 add attachment
 
 */
- (MGSNetAttachment *)addAttachment:(MGSNetAttachment *)attachment
{
	attachment.delegate = self;
	[_attachments addObject:attachment];
	attachment.index = [_attachments count] - 1;
	return attachment;
}

/*
 
 add attachment to created temp file path with required length
 
 */
- (MGSNetAttachment *)addAttachmentToCreatedTempFileWithRequiredLength:(unsigned long long)requiredLength
{

	// file path must exist and be readable
	MGSNetAttachment *attachment = [MGSNetAttachment attachmentWithStorageFacility:[self storageFacility]];

	if (!attachment) {
		return nil;
	}

	// set required attachment length
	attachment.requiredLength = requiredLength;

	return [self addAttachment:attachment];
}


/*
 
 property list representation
 
 */
- (NSArray *)propertyListRepresentation
{	
	if (!_attachments || [_attachments count] == 0) {
		return nil;
	}
	
	//NSMutableString *headerRep = [NSMutableString stringWithCapacity:5];
	NSMutableArray *attachmentDicts = [NSMutableArray arrayWithCapacity: 1];
	for (MGSNetAttachment *attachment in _attachments) {
		
		// the attachment must be valid ie: must reference an existing file that can be read
		if (![attachment validate]) {
			return nil;
		}
		//unsigned long long length = [attachment validatedLength];
		
		// string format
		//[headerRep appendFormat:@"%qu%@", length, MGSAttachmentSeparator];
		
		// add dict
		NSDictionary *dict = [attachment dictionaryRepresentation];
		[attachmentDicts addObject:dict];
	}
	
	return attachmentDicts;
	
	/*
	NSData *xmlData = [NSPropertyListSerialization dataFromPropertyList:attachmentDicts
																 format:NSPropertyListXMLFormat_v1_0
													   errorDescription:nil];
	if (!xmlData) {
		MLog(RELEASELOG, @"could not serialize attachments");
		return nil;
	}
	
	// remove trailing separator
	//[headerRep deleteCharactersInRange:NSMakeRange([headerRep length]-1, 1)];
	
	NSString *plistString = [[NSString alloc] initWithData:xmlData encoding:NSUTF8StringEncoding];
	
	return plistString;
	 */
}

/*
 
 parse property list representation
 
 */
- (void)parsePropertyListRepresentation:(NSArray *)attachmentsList
{
	
	NSUInteger attachmentIndex = 0;
	
	// loop through attachments dictionary
	for  (NSDictionary *dict in attachmentsList) {
		
		// validate the dict
		if (![dict isKindOfClass:[NSDictionary class]]) {
			MLog(RELEASELOG, @"bad attachment dictionary data in message");
			return;
		}
		
		// get attachment to parse dictionary representation
		MGSNetAttachment *attachment = [self attachmentAtIndex:attachmentIndex];
		[attachment parseDictionaryRepresentation:dict];
		attachmentIndex++;
	}
}

/*
 
 header representation
 
 */
- (NSString *)headerRepresentation
{
	if (!_attachments || [_attachments count] == 0) {
		return [[self class] defaultHeaderRepresentation];
	}
	
	NSMutableString *headerRep = [NSMutableString stringWithCapacity:5];
	for (MGSNetAttachment *attachment in _attachments) {
		
		// the attachment must be valid ie: must reference an existing file that can be read
		if (![attachment validate]) {
			return nil;
		}
		unsigned long long length = [attachment validatedLength];
		
		// string format
		[headerRep appendFormat:@"%qu%@", length, MGSAttachmentSeparator];
	}
	
	// remove trailing separator
	[headerRep deleteCharactersInRange:NSMakeRange([headerRep length]-1, 1)];
	
	return headerRep;
}

/*
 
 validated length of all attachments
 
 */
- (unsigned long long)validatedLength
{
	if (!_attachments || [_attachments count] == 0) {
		return 0;
	}

	unsigned long long validatedLength = 0;
	for (MGSNetAttachment *attachment in _attachments) {
		
		// the attachment must be valid ie: must reference an existing file that can be read
		if (![attachment validate]) {
			return 0;
		}
		validatedLength += [attachment validatedLength];
	}
	
	return validatedLength;
}

/*
 
 required length of all attachments
 
 the required length indicates the expected length of the attachment.
 
 */
- (unsigned long long)requiredLength
{
	if (!_attachments || [_attachments count] == 0) {
		return 0;
	}
	
	unsigned long long requiredLength = 0;
	for (MGSNetAttachment *attachment in _attachments) {
		requiredLength += [attachment requiredLength];
	}
	
	return requiredLength;
}

/*
 
 array
 
 */
- (NSArray *)array
{
	return [NSArray arrayWithArray:_attachments];
}

/*
 
 attachment at index
 
 */

- (MGSNetAttachment *)attachmentAtIndex:(NSUInteger)idx
{
	if (idx < [_attachments count]) {
		return [_attachments objectAtIndex:idx];
	}
	
	return nil;
}
/*
 
 count
 
 */
- (NSUInteger)count
{
	return [_attachments count];
}

/*
 
 generate file preview images
 
 */
- (void)generateAttachmentPreviews
{
	_attachmentPreviewImages = [NSMutableArray new];
	 
	
	// create operations to get previews asynchronously
	for (MGSNetAttachment *attachment in _attachments) { 
		
		BOOL useOperationQueue = YES;
		
		if (useOperationQueue) {
			NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:attachment
																				selector:@selector(generateFilePreview) object:nil];
			
			if (theOp) {
				MLog(DEBUGLOG, @"attachment preview operation queued for: %@", attachment);
			} else {
				MLog(DEBUGLOG, @"attachment preview operation NOT queued for: %@", attachment);
			}
			
			[self.operationQueue addOperation:theOp];
		} else {
			[attachment generateFilePreview];
		}
	}
	 
	
}
	

/*
 
 attachment preview available
 
 */
- (void)attachmentPreviewAvailable:(MGSNetAttachment *)attachment
{
	MLog(DEBUGLOG, @"attachment preview operation available for: %@", attachment);

	// add the attachment image to our array
	[_attachmentPreviewImages addObject:attachment.browserImage];
	[delegate reloadData];
}

/*
 
 operation queue
 
 */
- (NSOperationQueue *)operationQueue
{
	// lazy allocation
	if (!_operationQueue) {
		_operationQueue = [[NSOperationQueue alloc] init];
	}
	
	return _operationQueue;
}

/*
 
 finalize
 
 */
- (void)finalize
{
	MLog(DEBUGLOG, @"MGSNetAttachments finalized.");
	
	// dispose of our attachments
	for (MGSNetAttachment *attachment in _attachments) {
		[attachment dispose];
	}
	
	if (_storageFacility) {
		[_storageFacility deleteStorageFacility];
	}
	
	[super finalize];
}

@end



@implementation MGSNetAttachments(Private)

/*
 
 scan header representation
 
 */
- (BOOL)scanHeaderRepresentation:(NSString *)rep
{
	NSScanner *scanner = [NSScanner scannerWithString:rep];
	
	while (YES) {
		long long attachmentLength;
		
		// scan the attachment length
		if (![scanner scanLongLong:&attachmentLength]) {
			MLog(RELEASELOG, @"Could not scan attachment length");
			return NO;
		}
		
		// validate the length
#pragma mark warning try and find LONG_LONG_MAX
		//if (attachmentLength < 0 || attachmentLength == LONG_LONG_MAX || attachmentLength == LONG_LONG_MIN) {
		
		if (attachmentLength < 0) {
			MLog(RELEASELOG, @"Invalid attachment length");
			return NO;
		}
		
		// create temp file attachment
		MGSNetAttachment *attachment = [self addAttachmentToCreatedTempFileWithRequiredLength:attachmentLength];
		if (!attachment) {
			MLog(RELEASELOG, @"Cannot create temporary attachment file");
			return NO;
		}
		
		// scan over separator
		if (![scanner scanUpToStringAndOver:MGSAttachmentSeparator]) {
			break;
		}
	}
	
	return YES;
}

@end


