//
//  MGSResourceBrowserItem.m
//  KosmicTask
//
//  Created by Jonathan on 17/06/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSResourceItem.h"
#import "mlog.h"
#import <ORCDiscount/ORCDiscount.h>

NSString * MGSResourceOriginUser = @"User";
NSString * MGSResourceOriginMugginsoft = @"Mugginsoft";

// class extension
@interface MGSResourceItem()
- (BOOL)loadResourceType:(MGSResourceItemFileType)fileType;
- (BOOL)unloadResourceType:(MGSResourceItemFileType)fileType;
- (BOOL)saveResourceType:(MGSResourceItemFileType)fileType;
- (BOOL)persistResourceType:(MGSResourceItemFileType)fileType;
- (BOOL)deleteResourceType:(MGSResourceItemFileType)fileType;
- (BOOL)loadDerivedResourceType:(MGSDerivedResourceItemType)derivedType;
@end

@implementation MGSResourceItem

@synthesize delegate, name, origin, author, date, info, node, ID, stringResource, attributedStringResource,
editable, dictionaryResource, docFileType, markdownResource, htmlResource;

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
		docFileType = MGSResourceItemMarkdownFile;
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

/*
 
 - updateDocFileType:
 
 */
- (void)updateDocFileType:(MGSResourceItemFileType)value
{

	switch (value) {
			
		case MGSResourceItemMarkdownFile:;
			self.markdownResource = [self.attributedStringResource string];
			self.attributedStringResource = [[NSAttributedString alloc] initWithString:@""];
			break;
			
		case MGSResourceItemRTFDFile:;
			if (YES) {
				self.attributedStringResource = [[NSAttributedString alloc] initWithString: self.markdownResource];
			} else {
				NSData *data = [self.htmlResource dataUsingEncoding:NSUTF8StringEncoding];
				self.attributedStringResource = [[NSAttributedString alloc] initWithHTML:data documentAttributes:nil];
			}
			self.markdownResource = @"";
			break;
			
		default:
			break;
	}
	
	self.docFileType = value;
}

/*
 
 - stringForFileType:
 
 */
- (NSString *)stringForFileType:(MGSResourceItemFileType)fileType
{
    NSString *value = @"unknown";
    switch(fileType){
        
        case MGSResourceItemTextFile:
            value = @"text";
            break;
            
        case MGSResourceItemRTFDFile:
            value = @"RTF";
            break;
            
        case MGSResourceItemPlistFile:
            value = @"plist";
            break;
	
        case MGSResourceItemMarkdownFile:
            value = @"markdown";
            break;
        
        default:
            break;
    }
    
    return value;
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
	[self loadResourceType:MGSResourceItemMarkdownFile];
	
		
	// validate
	switch (self.docFileType) {
			
		case MGSResourceItemMarkdownFile:;
			if ([self.attributedStringResource length] > 0 && [self.markdownResource length] == 0) {
				self.docFileType = MGSResourceItemRTFDFile;
			}
			break;
			
		case MGSResourceItemRTFDFile:;
			if ([self.attributedStringResource length] == 0 && [self.markdownResource length] > 0) {
				self.docFileType = MGSResourceItemMarkdownFile;
			}
			break;
			
		default:
			break;
	}
}

/*
 
 - unload
 
 */
- (void)unload
{
	[self unloadResourceType:MGSResourceItemTextFile];
	[self unloadResourceType:MGSResourceItemRTFDFile];
	[self unloadResourceType:MGSResourceItemPlistFile];
	[self unloadResourceType:MGSResourceItemMarkdownFile];
}

/*
 
 - load
 
 */
- (void)loadDerivedResources
{
	[self loadDerivedResourceType:MGSDerivedResourceItemHTML];
}
	
/*
 
 - loadDerivedResourceType:
 
 */
- (BOOL)loadDerivedResourceType:(MGSDerivedResourceItemType)derivedType
{
	switch (derivedType) {
		case MGSDerivedResourceItemHTML: {;
			NSString *html = [ORCDiscount markdown2HTML:self.markdownResource];
			
			// default framework cssUrl is at [ORCDiscount cssURL]
			NSURL *cssURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"ResourceDocument" withExtension:@"css"];
			if (!cssURL) {
				cssURL = [ORCDiscount cssURL];
			}
			self.htmlResource = [ORCDiscount HTMLPage:html withCSSFromURL:cssURL];
			break;
		
		}
		default:
			return NO;
		break;
	}
	
	return YES;
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
		case MGSResourceItemTextFile: {;
			NSString *text = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
			if (!text) {
				text = @"";
			}
			
			self.stringResource = text;
			break;

		}
		case MGSResourceItemMarkdownFile: {;
			NSString *markdownText = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
			if (!markdownText) {
				markdownText = @"";
			}
			
			self.markdownResource = markdownText;
			
			[self loadDerivedResourceType:MGSDerivedResourceItemHTML];

			break;
			
		}
		case MGSResourceItemRTFDFile: {;
            NSAttributedString *atext = nil;
            NSError *docError = nil;

            /*
             On migrating to Lion we encounter:
             
             Error Domain=NSCocoaErrorDomain Code=257 "The file “5.rtfd” couldn’t be opened because you don’t have permission to view it." UserInfo=0x14bf910 {NSFilePath=/Users/Jonathan/Documents/KosmicTask/Application Tasks/Resources/Languages/AppleScript Cocoa/Templates/5.rtfd, NSUnderlyingError=0x245eb00 "The operation couldn’t be completed. Permission denied"}
             
             Previously the resource was loaded without issue as below.
             On lion however we get a sigbus error:
             
             NSAttributedString *atext = [[NSAttributedString alloc] initWithPath:testPath documentAttributes:NULL];
             
             To trigger the issue dsiplay the resource browser, collapse all the languages, expand them and then select the first item.
             
             */

            // the following works but discards images in the RTFD!
            if (YES) {
                // get path to rtf file
                NSString *filePath = [path stringByAppendingPathComponent:@"TXT.rtf"];
                
                // rtf data might not have been written out yet
                if ([[NSFileManager  defaultManager] fileExistsAtPath:filePath]) {
                    
                    // get data - but any images will not be loaded!
                    NSData *data = [NSData dataWithContentsOfFile:filePath options:0 error:&docError];
                    
                    // get attributed string
                    if (!docError) {
                        atext = [[NSAttributedString alloc] initWithData:data options:nil documentAttributes:NULL error:&docError];
                    }
                }
            }

            /* fails
            NSFileWrapper *wrapper = [[NSFileWrapper alloc] initWithURL:[NSURL fileURLWithPath:path] options:NSFileWrapperReadingImmediate error:nil];
            atext = [[NSAttributedString alloc] initWithRTFDFileWrapper:wrapper documentAttributes:NULL];
             */
            
            /* fails too
            atext = [[NSAttributedString alloc] initWithURL:[NSURL fileURLWithPath:path] documentAttributes:NULL];
            */
            
            if (!atext) {
				NSFont *font = [NSFont fontWithName:@"Helvetica" size:14.0f];
				NSColor *colour = [NSColor blackColor];
				NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
												 font, NSFontAttributeName, 
												 colour, NSForegroundColorAttributeName, 
												 nil];
				
				// string must be non null to change NSTextView typing attributes.
				// see: http://developer.apple.com/mac/library/documentation/Cocoa/Conceptual/TextUILayer/Tasks/SetTextAttributes.html#//apple_ref/doc/uid/20000936-CJBJHGAG
                
                if (docError) {
                    atext = [[NSAttributedString alloc] initWithString:[docError localizedDescription]];
                } else {
                    atext = [[NSAttributedString alloc] initWithString:@"\n" attributes:attrsDictionary];
                }
			}
			
			self.attributedStringResource = atext;
			break;
		
		}
		case MGSResourceItemPlistFile: {;
			NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
			if (!dict) {
				dict = [NSDictionary new];
			}
			self.dictionaryResource = dict;
			break;
			
		}
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
		
		case MGSResourceItemMarkdownFile:
			self.markdownResource = nil;
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
	
	if (![self saveResourceType:MGSResourceItemPlistFile]) {
		success = NO;
	}

	switch (self.docFileType) {
			
		case MGSResourceItemRTFDFile:
			if (![self saveResourceType:MGSResourceItemRTFDFile]) {
				success = NO;
			}
			[self deleteResourceType:MGSResourceItemMarkdownFile];
			break;
	
		case MGSResourceItemMarkdownFile:
			if (![self saveResourceType:MGSResourceItemMarkdownFile]) {
				success = NO;
			}
			[self deleteResourceType:MGSResourceItemRTFDFile];
			break;
			
		default:
			NSAssert(NO, @"invalid docFileType");
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

	if (![self deleteResourceType:MGSResourceItemMarkdownFile]) {
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
	NSString *text = nil;
	NSError *error = nil;
	
    // get path
	NSString *path = [self.delegate pathToResource:self type:fileType];
	if (!path) {
		return NO;
	}
    
    // create folder
    NSString *folder = [path stringByDeletingLastPathComponent];
	if (![[NSFileManager defaultManager] createDirectoryAtPath:folder
                              withIntermediateDirectories:YES 
                                                    attributes:nil error:&error]) {
        MLogInfo(@"Error creating %@ (%@): %@\nFolder: %@", [self title], [self stringForFileType:fileType], [error localizedDescription], folder);
        return NO;
    }
    

    [self deleteResourceType:fileType];
    
	switch (fileType) {
			
		case MGSResourceItemTextFile:
			
			if (!stringResource) stringResource = [[NSString alloc] initWithString:@""];
			
			// we persist as plain text
			text = stringResource;
			success = [text writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
			break;

		case MGSResourceItemMarkdownFile:;
			
			if (!markdownResource) markdownResource = [[NSString alloc] initWithString:@""];
			
			// we persist as plain text
			text = markdownResource;
			success = [text writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
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
				
                success = [wrapper writeToURL:[NSURL fileURLWithPath:[path stringByExpandingTildeInPath]] 
                                        options:NSFileWrapperWritingAtomic & NSFileWrapperWritingWithNameUpdating
                                        originalContentsURL:nil 
                                        error:&error];
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
		MLogInfo(@"Error writing %@ (%@): %@\nPath: %@", [self title], [self stringForFileType:fileType], [error localizedDescription], path);
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
	
	BOOL success = YES;
	
	NSString *path = [self.delegate pathToResource:self type:fileType];
	if (!path) {
		return NO;
	}
	
	switch (fileType) {
		case MGSResourceItemTextFile:;
		case MGSResourceItemRTFDFile:;
		case MGSResourceItemPlistFile:;
		case MGSResourceItemMarkdownFile:;
            if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
                success = [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
            }
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
								@"DocFileType", @"docFileType",
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
	copy.docFileType = [self docFileType];
	copy.stringResource = [self.stringResource copy];
	copy.attributedStringResource = [self.attributedStringResource copy];
	copy.dictionaryResource = [self.dictionaryResource copy];
	copy.markdownResource = [self.markdownResource copy];
	copy.htmlResource = [self.htmlResource copy];
	
	return copy;
}

@end
