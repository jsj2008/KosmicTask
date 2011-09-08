//
//  MGSResourceBrowserItem.h
//  KosmicTask
//
//  Created by Jonathan on 17/06/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSResourceBrowserNode.h"

extern NSString * MGSResourceOriginUser;
extern NSString * MGSResourceOriginMugginsoft;

typedef enum _MGSResourceItemFileType {
	MGSResourceItemTextFile = 0,
	MGSResourceItemRTFDFile = 1,
	MGSResourceItemPlistFile = 2,
	MGSResourceItemMarkdownFile = 3,
}  MGSResourceItemFileType;

typedef enum _MGSDerivedResourceItemType {
	MGSDerivedResourceItemHTML = 0,
}  MGSDerivedResourceItemType;

@class MGSResourceItem;

@protocol MGSResourceItemDelegate <NSObject>
@required
- (NSNumber *)nextResourceID;
- (NSString *)pathToResource:(MGSResourceItem *)resource type:(MGSResourceItemFileType)resourceType;
- (BOOL)save;
- (NSString *)defaultAuthor;
@end

@interface MGSResourceItem : NSObject <NSCopying> {
@private
	NSNumber *ID;
	NSString *name;
	NSString *origin;
	NSString *author;
	NSDate *date;
	NSString *info;
	MGSResourceItemFileType docFileType;
	
	BOOL editable;
	id <MGSResourceItemDelegate> delegate;
	MGSResourceBrowserNode *node;
		
	// file based properties
	NSString *stringResource;
	NSAttributedString *attributedStringResource;
	id dictionaryResource;
	NSString *markdownResource;
	NSString *htmlResource;
}
@property id delegate;
@property (copy) NSString *name;
@property (copy) NSString *origin;
@property (copy) NSString *author;
@property (copy) NSDate *date;
@property (copy) NSString *info;
@property (assign) MGSResourceBrowserNode *node;
@property (copy) NSNumber *ID;
@property (assign) NSString *stringResource;
@property (assign) NSAttributedString *attributedStringResource;
@property (assign) id dictionaryResource;
@property (assign) NSString *markdownResource;
@property (assign) NSString *htmlResource;
@property BOOL editable;
@property MGSResourceItemFileType docFileType;

+ (NSString *)title;
- (NSString *)title;
+ (BOOL)canDefaultResource;
- (id)initWithDelegate:(id <MGSResourceItemDelegate>)theDelegate;
- (NSComparisonResult)caseInsensitiveNameCompare:(MGSResourceItem *)target;
- (NSDictionary *)plistRepresentation;
+ (id)resourceWithDictionary:(NSDictionary *)dict;
- (id)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)keyMapping;
- (void)load;
- (void)unload;
- (BOOL)save;
- (BOOL)delete;
- (id)duplicate;
- (id)duplicateWithDelegate:(id <MGSResourceItemDelegate>)dupDelegate;
- (BOOL)canDefaultResource;
- (void)updateDocFileType:(MGSResourceItemFileType)value;
- (void)loadDerivedResources;
- (NSString *)stringForFileType:(MGSResourceItemFileType)fileType;
@end





