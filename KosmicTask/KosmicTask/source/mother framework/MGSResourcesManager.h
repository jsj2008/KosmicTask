//
//  MGSResourcesManager.h
//  KosmicTask
//
//  Created by Jonathan on 15/06/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSResourceBrowserNode.h"
#import "MGSResourceItem.h"
#import "MGSImageManager.h"

@class MGSResourcesManager;

extern NSString *MGSResourcesManagerWillChange;
extern NSString *MGSResourcesManagerDidChange;
extern NSString *MGSResourceAdded;
extern NSString *MGSResourceDeleted;
extern NSString *MGSDefaultResourceIDChanged;

@protocol MGSResourcesManagerDelegate <NSObject>
@optional
- (id <MGSResourcesManagerDelegate>)rootManagerDelegate;
@required
- (void)resourcesManager:(MGSResourcesManager *)manager cannotMutateWithSelector:(SEL)selector object:(id)object;
- (void)resourcesManager:(MGSResourcesManager *)manager didMutate:(NSDictionary *)changes;
@end

@interface MGSResourcesManager : NSObject <MGSResourceItemDelegate, MGSResourcesManagerDelegate, NSCopying> {
	@private
	NSString *resourcePath;
	NSMutableArray *resourcesManagers;
	NSMutableArray *resources;
	NSArray *resourceNames;
	id <MGSResourcesManagerDelegate> delegate;
	NSString *resourceName;
	NSString *managerPath;
	NSString *resourceFolder;
	NSImage *nodeImage;
	Class resourceClass;
	NSString *resourcesPlistKey;
	MGSResourceBrowserNode *managerNode;
	NSNumber *defaultResourceID;
	NSString *origin;
	BOOL canMutate;
}

@property (readonly) NSMutableArray *resourcesManagers;
@property id <MGSResourcesManagerDelegate> delegate;
@property (copy, readonly) NSString *resourcePath;
@property (copy, readonly) NSString *managerPath;
@property (copy, readonly) NSString *resourceName;
@property (copy, readonly) NSString *resourceFolder;
@property (assign) NSMutableArray *resources;
@property (copy)NSImage *nodeImage;
@property Class resourceClass;
@property (copy) NSString *resourcesPlistKey;
@property (assign) MGSResourceBrowserNode *managerNode;
@property (assign) NSArray *resourceNames;
@property (copy) NSNumber *defaultResourceID;;
@property (copy) NSString *origin;
@property BOOL canMutate;

- (id)newResource;
- (id)initWithPath:(NSString *)aPath name:(NSString *)aName folder:(NSString *)aFolder;
- (void)addToTree:(MGSResourceBrowserNode *)parentNode;
- (void)createResourcesManagers;
- (NSDictionary *)loadResources;
- (NSString *)nodeName;
- (NSString *)plistName;
- (NSMutableArray *)allResources;
- (NSMutableDictionary *)plistRepresentation;
- (BOOL)save;

- (void)addResource:(MGSResourceItem *)newResource;
- (void)deleteResource:(MGSResourceItem *)newResource;
- (MGSResourceItem *)addNewResource;
- (NSNumber *)nextResourceID;
- (NSString *)pathToResource:(MGSResourceItem *)resource type:(MGSResourceItemFileType)resourceType;
- (NSNumber *)nextResourceID;
- (NSImage *)defaultNodeImage;
- (void)addDuplicateResource:(MGSResourceItem *)aResource;
- (NSString *)defaultAuthor;
- (MGSResourceItem *)resourceWithID:(NSNumber *)theID;
- (MGSResourceItem *)defaultResource;
- (NSImage *)originImage;
- (BOOL)canAddResources;
- (void)resourcesManager:(MGSResourcesManager *)manager cannotMutateWithSelector:(SEL)selector object:(id)object;
- (BOOL)mutateWithSelector:(SEL)selector object:(id)object;
- (id <MGSResourcesManagerDelegate>)rootManagerDelegate;
- (MGSResourcesManager *)managerForResourceClass:(Class)klass;
- (BOOL)supportsMutation;
@end
