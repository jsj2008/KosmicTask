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
	MGSResourceItemTextFile,
	MGSResourceItemRTFDFile,
	MGSResourceItemPlistFile
}  MGSResourceItemFileType;

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
	BOOL editable;
	id <MGSResourceItemDelegate> delegate;
	MGSResourceBrowserNode *node;
		
	// file based properties
	NSString *stringResource;
	NSAttributedString *attributedStringResource;
	id dictionaryResource;
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
@property BOOL editable;

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
@end





