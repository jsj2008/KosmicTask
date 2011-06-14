//
//  MGSResourceBrowserItem.m
//  KosmicTask
//
//  Created by Jonathan on 17/06/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSResourceItem.h"
#import "mlog.h"

NSString * MGSResourceOriginUser = @"User";
NSString * MGSResourceOriginMugginsoft = @"Mugginsoft";

// class extension
@interface MGSResourceItem()
- (BOOL)loadResourceType:(MGSResourceItemFileType)fileType;
- (BOOL)unloadResourceType:(MGSResourceItemFileType)fileType;
- (BOOL)saveResourceType:(MGSResourceItemFileType)fileType;
- (BOOL)persistResourceType:(MGSResourceItemFileType)fileType;
- (BOOL)deleteResourceType:(MGSResourceItemFileType)fileType;
@end

@implementation MGSResourceItem

@synthesize delegate, name, origin, author, date, info, node, ID, stringResource, attributedStringResource,
editable, dictionaryResource;

#pragma mark -
#pragma mark Class methods
/*
 
 - title
 
 */
+ (NSString *)title
{
	return @"Resource";
}

/*
 
 + resourceWithDictionary:
 
 */
+ (id)resourceWithDictionary:(NSDictionary *)dict
{
	return [[self alloc] initWithDictionary:dict];
}

/*
 
 + canDefaultResource
 
 */
+ (BOOL)canDefaultResource
{
	return NO;
}

#pragma mark -
#pragma mark Initialization
/*
 
 - init
 
 */
- (id)init
{
	return [self initWithDelegate:nil];
}

/*
 
 - initWithDelegate:
 
 designated initialiser
 
 */
- (id)initWithDelegate:(id <MGSResourceItemDelegate>)theDelegate
{
	self = [super init];
	if (self) {
		editable = YES;
		delegate = theDelegate;
		name = NSLocalizedString(@"untitled", @"untitled resource");
		origin = MGSResourceOriginUser;
		date = [NSDate date];
		author = [self.delegate defaultAuthor];
		ID = [NSNumber numberWithInteger:1];
	}
	
	return self;
}

/*
 
 - initWithDictionary:
 
 */
- (id)initWithDictionary:(NSDictionary *)dict
{
	self = [self initWithDelegate:nil];
	if (self) {
		for (NSString *key in [[self keyMapping] allKeys]) {
			NSString *key2 = [[self keyMapping] objectForKey:key];
			id object = [dict objectForKey:key2];
			if (object) {
				[self setValue:object forKey:key];
			}
		}
	}
	
	return self;
}

#pragma mark -
#pragma mark Accessors
/*
 
 - title
 
 */
- (NSString *)title
{
	return[[self class] title];
}

/*
 
 - stringResource
 
 */
- (NSString *)stringResource
{
	if (!stringResource) {
		[self loadResourceType:MGSResourceItemTextFile];
	}
	return stringResource;
}

/*
 
 - attributedStringResource
 
 */
- (NSAttributedString *)attributedStringResource
{
	if (!attributedStringResource) {
		[self loadResourceType:MGSResourceItemTextFile];
	}
	return attributedStringResource;
}
/*
 
 - dictionaryResource
 
 */
- (NSAttributedString *)dictionaryResource
{
	if (!dictionaryResource) {
		[self loadResourceType:MGSResourceItemPlistFile];
	}
	return dictionaryResource;
}

/*
 
 - setOrigin:
 
 */
- (void)setOrigin:(NSString *)value
{
	origin = value;
	self.editable = ![self.origin isEqualToString:MGSResourceOriginMugginsoft];
}

/*
 
 - canDefaultResource
 
 */
- (BOOL)canDefaultResource
{
	return [[self class] canDefaultResource];
}

#pragma mark -
#pragma mark Comparing
/*
 
 - caseInsensitiveNameCompare:
 
 */
- (NSComparisonResult)caseInsensitiveNameCompare:(MGSResourceItem *)target
{
	return [self.name caseInsensitiveCompare:target.name];
}

#pragma mark -
#pragma mark Persistence
/*
 
 - plistRepresentation
 
 */
- (NSDictionary *)plistRepresentation
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:10];
	
	for (NSString *key in [[self keyMapping] allKeys]) {
		id object = [self valueForKey:key];
		if (object) {
			NSString *key2 = [[self keyMapping] objectForKey:key];
			[dict setObject:object forKey:key2];
		}
	}
	
	return dict;
}

/*
 
 - load
 
 */
- (void)load
{
	[self loadResourceType:MGSResourceItemTextFile];
	[self loadResourceType:MGSResourceItemRTFDFile];
	[self loadResourceType:MGSResourceItemPlistFile];
}

/*
 
 - unload
 
 */
- (void)unload
{
	[self unloadResourceType:MGSResourceItemTextFile];
	[self unloadResourceType:MGSResourceItemRTFDFile];
	[self unloadResourceType:MGSResourceItemPlistFile];
}

/*
 
 loadResourceType:
 
 */
- (BOOL)loadResourceType:(MGSResourceItemFileType)fileType
{
	NSString *path = [self.delegate pathToResource:self type:fileType];
	if (!path) {
		return NO;
	}
	
	switch (fileType) {
		case MGSResourceItemTextFile:;
			NSString *text = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
			if (!text) {
				text = @"";
			}
			
			self.stringResource = text;
			break;
			
		case MGSResourceItemRTFDFile:;
			NSAttributedString *atext = [[NSAttributedString alloc] initWithPath:path documentAttributes:NULL];
			if (!atext) {
				NSFont *font = [NSFont fontWithName:@"Helvetica" size:14.0f];
				NSColor *colour = [NSColor blackColor];
				NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
												 font, NSFontAttributeName, 
												 colour, NSForegroundColorAttributeName, 
												 nil];
				
				// string must be non null to change NSTextView typing attributes.
				// see: http://developer.apple.com/mac/library/documentation/Cocoa/Conceptual/TextUILayer/Tasks/SetTextAttributes.html#//apple_ref/doc/uid/20000936-CJBJHGAG
				atext = [[NSAttributedString alloc] initWithString:@"\n" attributes:attrsDictionary];
			}
			
			self.attributedStringResource = atext;
			break;
		
		case MGSResourceItemPlistFile:;
			NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
			if (!dict) {
				dict = [NSDictionary new];
			}
			self.dictionaryResource = dict;
			break;
			
		default:
			return NO;
	}
	
	return YES;
}

/*
 
 unloadResourceType:
 
 */
- (BOOL)unloadResourceType:(MGSResourceItemFileType)fileType
{
	switch (fileType) {
		case MGSResourceItemTextFile:
			self.stringResource = nil;
			break;
			
		case MGSResourceItemRTFDFile:
			self.attributedStringResource = nil;
			break;

		case MGSResourceItemPlistFile:
			self.dictionaryResource = nil;
			break;
			
		default:
			return NO;
	}
	
	return YES;
}

/*
 
 - save
 
 */
- (BOOL)save
{
	BOOL success = YES;
		
	if (![self saveResourceType:MGSResourceItemTextFile]) {
		success = NO;
	}
	
	if (![self saveResourceType:MGSResourceItemRTFDFile]) {
		success = NO;
	}

	if (![self saveResourceType:MGSResourceItemPlistFile]) {
		success = NO;
	}
	
	return success;
}

/*
 
 - delete
 
 */
- (BOOL)delete
{	
	BOOL success = YES;
	
	if (![self deleteResourceType:MGSResourceItemTextFile]) {
		success = NO;
	}
	
	if (![self deleteResourceType:MGSResourceItemRTFDFile]) {
		success = NO;
	}
	
	return success;
}

/*
 
 - saveResourceType:
 
 */
- (BOOL)saveResourceType:(MGSResourceItemFileType)fileType
{
	if (![self persistResourceType:fileType]) {
		return YES;
	}
	
	BOOL success = NO;
	
	NSString *path = [self.delegate pathToResource:self type:fileType];
	if (!path) {
		return NO;
	}
	
	switch (fileType) {
			
		case MGSResourceItemTextFile:;
			
			if (!stringResource) stringResource = [[NSString alloc] initWithString:@""];
			
			// we persist as plain text
			NSString *text = stringResource;
			success = [text writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:NULL];
			break;
			
		case MGSResourceItemRTFDFile:;
			
			if (!attributedStringResource) attributedStringResource = [[NSAttributedString alloc] initWithString:@""];

			// we persist as RTF
			if (NO) {
				NSData *rtfData = [attributedStringResource 
									RTFDFromRange:NSMakeRange(0, [self.attributedStringResource length]) 
									documentAttributes:nil];
				success = [rtfData writeToFile:path atomically:YES];
			} else {
				NSFileWrapper *wrapper = [attributedStringResource 
				 RTFDFileWrapperFromRange:NSMakeRange(0, [self.attributedStringResource length]) 
				 documentAttributes:nil];
				
				success = [wrapper writeToFile:path atomically:YES updateFilenames:YES];
			}
			break;
			
		case MGSResourceItemPlistFile:;
			
			if (!dictionaryResource) dictionaryResource = [NSDictionary new];
			
			success = [dictionaryResource writeToFile:path atomically:YES];
			break;
			
		default:
			return NO;
	}
	
	if (!success) {
		MLogInfo(@"error writing to: %@", path);
		return NO;
	}

	return YES;
}

/*
 
 - deleteResourceType:
 
 */
- (BOOL)deleteResourceType:(MGSResourceItemFileType)fileType
{
	if (![self persistResourceType:fileType]) {
		return YES;
	}
	
	BOOL success = NO;
	
	NSString *path = [self.delegate pathToResource:self type:fileType];
	if (!path) {
		return NO;
	}
	
	switch (fileType) {
		case MGSResourceItemTextFile:;
		case MGSResourceItemRTFDFile:;
		case MGSResourceItemPlistFile:;
			success = [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
			break;			
			
		default:
			return NO;
	}
	
	if (!success) {
		MLogInfo(@"error deleting : %@", path);
		return NO;
	}
	
	return YES;
}

/*
 
 - persistResourceType:
 
 */
- (BOOL)persistResourceType:(MGSResourceItemFileType)fileType
{
#pragma unused(fileType)
	
	return YES;
}
#pragma mark -
#pragma mark Key management
/*
 
 - keyMapping
 
 */
- (NSDictionary *)keyMapping
{
	NSDictionary *keyMapping = [NSDictionary dictionaryWithObjectsAndKeys:
								@"Name", @"name", 
								@"Date", @"date", 
								@"Author", @"author", 
								@"Info", @"info", 
								//@"Origin", @"origin", 
								@"ID", @"ID",
								nil];
	return keyMapping;
}


#pragma mark -
#pragma mark Copying

/*
 
 - duplicate
 
 */
- (id)duplicate
{
	return [self duplicateWithDelegate:self.delegate];	
}
/*
 
 - duplicate
 
 */
- (id)duplicateWithDelegate:(id <MGSResourceItemDelegate>)dupDelegate
{
	// copy
	MGSResourceItem *copy = [self copy];
	copy.delegate = dupDelegate;
	
	copy.name = [NSString stringWithFormat:@"%@ %@", self.name, NSLocalizedString(@"copy", @"Resource copy name")];
	copy.origin = MGSResourceOriginUser;
	copy.date = [NSDate date];
	copy.author = [copy.delegate defaultAuthor];
	
	// assign new resource ID
	if ([copy.delegate respondsToSelector:@selector(nextResourceID)]) {
		copy.ID = [copy.delegate nextResourceID];
	} else {
		copy = nil;
	}
	
	// save copy
	if (copy) {
		[copy save];
	}
	
	return copy;
	
}

/*
 
 - copyWithZone:
 
 */
- (id)copyWithZone:(NSZone *)zone
{
#pragma unused(zone)
	
	// copy
	MGSResourceItem *copy = [[[self class] alloc] initWithDelegate:delegate];
	copy.info = [self.info copy];
	copy.name = [self.name copy];
	copy.origin = [self.origin copy];
	copy.date = [self.date copy];
	copy.author = [self.author copy];
	copy.ID = [self.ID copy];
	copy.stringResource = [self.stringResource copy];
	copy.attributedStringResource = [self.attributedStringResource copy];
	copy.dictionaryResource = [self.dictionaryResource copy];
	
	return copy;
}

@end
