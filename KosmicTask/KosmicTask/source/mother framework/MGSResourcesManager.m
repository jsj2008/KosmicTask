//
//  MGSResourcesManager
//  KosmicTask
//
//  Created by Jonathan on 15/06/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSResourcesManager.h"
#import "MGSPath.h"
#import "MGSScript.h"
#import "mlog.h"
#import "MGSOriginTransformer.h"
#import "MGSImageManager.h"

#define MGS_DEFAULT_RESOURCEID [NSNumber numberWithInteger:1]

NSString *MGSResourcesManagerWillChange = @"MGSResourcesManagerWillChange";
NSString *MGSResourcesManagerDidChange = @"MGSResourcesManagerDidChange";
NSString *MGSResourceAdded = @"MGSResourceAdded";
NSString *MGSResourceDeleted = @"MGSResourceDeleted";
NSString *MGSDefaultResourceIDChanged = @"MGSDefaultResourceIDChanged";

// class extension
@interface MGSResourcesManager()
- (NSString *)makeResourcePath;
- (void)cannotMutateWithSelector:(SEL)selector object:(id)object;
- (void)didMutate:(NSDictionary *)changes;
- (void)addResource_:(MGSResourceItem *)newResource;

@property (copy) NSString *resourcePath;
@property (copy) NSString *managerPath;
@property (copy) NSString *resourceName;
@property (copy) NSString *resourceFolder;
@end

@implementation MGSResourcesManager

#pragma mark - 
#pragma mark Synthesizers

@synthesize delegate, resourcesManagers, resourcePath, resourceName, resourceFolder, managerPath, 
 nodeImage, resourceClass, resourcesPlistKey, managerNode, resources, resourceNames, defaultResourceID,
origin, canMutate;

#pragma mark -
#pragma mark Class methods
/*
 
 + initialize
 
 */

+ (void)initialize
{
		
	// register subclass with the language node
	[MGSResourceBrowserNode registerClass:self
								  options:[NSDictionary dictionaryWithObjectsAndKeys:@"nodeName", @"name", nil]];
	
}

#pragma mark -
#pragma mark Initialization
/*
 
 - initWithPath:name
 
 designated initaliser
 
 */
- (id)initWithPath:(NSString *)aPath name:(NSString *)aName folder:(NSString *)aFolder
{
	self = [super init];
	if (self) {
		
		// validate
		if (!aPath || !aName) {
			return nil;
		}

		canMutate = NO;
		
		// path components
		managerPath = aPath;
		resourceName = aName;
		resourceFolder = aFolder;
		resourcePath = [self makeResourcePath];
		nodeImage = [self defaultNodeImage];
		
		// create manager node
		managerNode = [MGSResourceBrowserNode treeNodeWithRepresentedObject:self];
		managerNode.image = self.nodeImage;
		managerNode.hasCount = YES;
		
		resources = [NSMutableArray arrayWithCapacity:10];
		defaultResourceID = MGS_DEFAULT_RESOURCEID;
		
		// create resources managers
		resourcesManagers = [NSMutableArray arrayWithCapacity:5];
		[self createResourcesManagers];
		
		// load resources
		if (aFolder) {
			[self loadResources];
		}
	}
	return self;
	
}

/*
 
 - init
 
 */
- (id)init
{
	return [self initWithPath:nil name:nil folder:nil];
}

#pragma mark -
#pragma mark Delegate
/*
 
 - setDelegate
 
 */
- (void)setDelegate:(id <MGSResourcesManagerDelegate>)aDelegate
{
	delegate = aDelegate;
}

/*
 
 - rootManagerDelegate
 
 */
- (id <MGSResourcesManagerDelegate>)rootManagerDelegate
{
	if ([self.delegate isKindOfClass:[MGSResourcesManager class]]) {
		return [self.delegate rootManagerDelegate];
	}
		 
	return self.delegate;
}

#pragma mark -
#pragma mark Accessors


/*
 
 - setDefaultResourceID:
 
 */
- (void) setDefaultResourceID:(NSNumber *)value
{
	if (!value) {
		value = [NSNumber numberWithInteger:-1];
	}
	
	if ([[self resourceClass] canDefaultResource]) {
		[[self defaultResource].node setStatusImage:nil];
	}
	
	defaultResourceID = value;
	
	if ([[self resourceClass] canDefaultResource]) {
		[[self defaultResource].node setStatusImage:[[[MGSImageManager sharedManager] defaultResource] copy]];
	}
	
	NSDictionary  *changes = [NSDictionary dictionaryWithObjectsAndKeys:[self defaultResource], MGSDefaultResourceIDChanged, nil];
	
	// post notification
	/*[[NSNotificationCenter defaultCenter] 
	 postNotificationName:MGSResourcesManagerDidChange 
	 object:self 
	 userInfo:changes];
	*/
	[self save];
	
	// did mutate
	[self didMutate:changes];
}

/*
 
 - defaultResource
 
 */
- (MGSResourceItem *)defaultResource
{
	MGSResourceItem *resource = nil;
	if (self.defaultResourceID) {
		resource = [self resourceWithID:self.defaultResourceID];
	}
	
	return resource;
}

/*
 
 - defaultAuthor
 
 */
- (NSString *)defaultAuthor
{
	return [MGSScript defaultAuthor];
}

/*
 
 - setOrigin:
 
 */
- (void)setOrigin:(NSString *)value
{
	origin = value;
	
	if (self.resourcesManagers && [self.resourcesManagers count] > 0) {
		[self.resourcesManagers makeObjectsPerformSelector:_cmd withObject:value];	
	}
	
	[resources makeObjectsPerformSelector:_cmd withObject:value];	
		
}

/*
 
 - resourceWithID:
 
 */
- (MGSResourceItem *)resourceWithID:(NSNumber *)theID
{
	if ([theID integerValue] == -1) {
		return nil;
	}
	
	for (MGSResourceItem *resource in resources) {
		if ([resource.ID integerValue] == [theID integerValue]) {
			return resource;
		}
	}
	
	return nil;
}

#pragma mark -
#pragma mark Resource managers


/*
 
 - newResource
 
 */
- (MGSResourceItem *)newResource
{
	// create resource
	MGSResourceItem *resource = [[self.resourceClass alloc] init];
	
	resource.ID = [self nextResourceID];
	
	return resource;
}

/*
 
 - addResource
 
 */
- (void)addResource:(MGSResourceItem *)newResource
{
	if (self.canMutate) {
		
		[self addResource_:newResource];
		
		// post notification
		[[NSNotificationCenter defaultCenter] 
		 postNotificationName:MGSResourcesManagerDidChange 
		 object:self 
		 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:newResource, MGSResourceAdded, nil]];	
		
	} else {
		[self cannotMutateWithSelector:_cmd object:newResource];  
	}
}

/*
 
 - addResource_
 
 */
- (void)addResource_:(MGSResourceItem *)newResource
{
	newResource.delegate = self;
	
	// note that we maintain the resources array 
	// separate to the managerNode mutableChildNodes
	// due to the fact that our resource is not an NSTreeNode subclass
	
	// add to resources array
	[self.resources addObject:newResource];
	
	// add to manager node
	MGSResourceBrowserNode *resourceNode = [MGSResourceBrowserNode treeNodeWithRepresentedObject:newResource];
	resourceNode.image = self.nodeImage;
	newResource.node = resourceNode;
	[[self.managerNode mutableChildNodes] addObject:resourceNode];
}

/*
 
 - addDuplicateResource:
 
 */
- (void)addDuplicateResource:(MGSResourceItem *)aResource
{
	if (!aResource) return;
	
	if (self.canMutate) {
		MGSResourceItem *resourceCopy = [aResource duplicateWithDelegate:self];
		[self addResource:resourceCopy];
	} else {
		[self cannotMutateWithSelector:_cmd object:aResource];  
	}
}


/*
 
 - deleteResource
 
 */
- (void)deleteResource:(MGSResourceItem *)resource
{
	if (!resource) return;
	
	NSAssert([resource isKindOfClass:[MGSResourceItem class]], @"bad resource class");
	
	// post notification
	[[NSNotificationCenter defaultCenter] 
	 postNotificationName:MGSResourcesManagerWillChange 
	 object:self 
	 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:resource, MGSResourceDeleted, nil]];
	
	// note that we maintain the resources array 
	// separate to the managerNode mutableChildNodes
	// due to the fact that our resource is not an NSTreeNode subclass
	
	// remove from resources array
	[self.resources removeObject:resource];
	
	// remove from manager node
	[[self.managerNode mutableChildNodes] removeObject:resource.node];
	
	// post notification
	[[NSNotificationCenter defaultCenter] 
	 postNotificationName:MGSResourcesManagerDidChange 
	 object:self 
	 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:resource, MGSResourceDeleted, nil]];
	
	[resource delete];
}

/*
 
 - addNewResource
 
 */
- (MGSResourceItem *)addNewResource
{
	// create resource
	MGSResourceItem *resource = [self newResource];
	
	// add it
	[self addResource:resource];
	
	return resource;
}

#pragma mark -
#pragma mark Resource managers
/*
 
 - createResourcesManagers
 
 */
- (void)createResourcesManagers
{
}

/*
 
 - managerForResourceClass:
 
 */
- (MGSResourcesManager *)managerForResourceClass:(Class)klass
{
	for (MGSResourcesManager *manager in self.resourcesManagers) {
		if (manager.resourceClass == klass) {
			return manager;
		}
	}
	
	return nil;
}

#pragma mark -
#pragma mark Permissions

/*
 
 - canAddResources
 
 */
- (BOOL)canAddResources
{
	if ([self.resourcesManagers count] > 0) {
		return NO;
	} else {
		return self.canMutate;
	}
}

#pragma mark -
#pragma mark Mutation
/*
 
 - cannotMutateWithSelector:object:
 
 */
- (void)cannotMutateWithSelector:(SEL)selector object:(id)object
{	
	if ([self.delegate respondsToSelector:@selector(resourcesManager:cannotMutateWithSelector:object:)]) {
		[self.delegate resourcesManager:self cannotMutateWithSelector:selector object:object];
	}
}


/*
 
 - resourcesManager:cannotMutateWithSelector:object:
 
 */
- (void)resourcesManager:(MGSResourcesManager *)manager cannotMutateWithSelector:(SEL)selector object:(id)object
{
	
#pragma unused(manager)
	
	[self cannotMutateWithSelector:selector object:object];
}

/*
 
 - mutateWithSelector:object:
 
 */
- (BOOL)mutateWithSelector:(SEL)selector object:(id)object
{
	if ([self.resourcesManagers count] > 0) {
		for (MGSResourcesManager *manager in self.resourcesManagers) {
			
			if ([object isKindOfClass:[manager resourceClass]]) {
				return [manager mutateWithSelector:selector object:object];
			}
		}
		return NO;
	}
	
	if (![object isKindOfClass:[self resourceClass]]) {
		return NO;
	}
	
	if (![self respondsToSelector:selector]) {
		return NO;
	}
	
	[self  performSelector:selector withObject:object];
	
	return YES;
}

/*
 
 - didMutate:
 
 */
- (void)didMutate:(NSDictionary *)changes
{
	if ([self.delegate respondsToSelector:@selector(resourcesManager:didMutate:)]) {
		[self.delegate resourcesManager:self didMutate:changes];
	}
}

/*
 
 - resourcesManager:didMutate:
 
 */
- (void)resourcesManager:(MGSResourcesManager *)manager didMutate:(NSDictionary *)changes
{
	
#pragma unused(manager)
	
	[self didMutate:changes];
}


#pragma mark -
#pragma mark Resources
/*
 
 - loadResources
 
 */
- (NSDictionary *)loadResources
{	
	NSString *path = [self.resourcePath stringByAppendingPathComponent:self.plistName];
	
	// get dictionary
	NSData *data = [NSData dataWithContentsOfFile:path];
	NSPropertyListFormat format;
	NSMutableDictionary *resourceDict = [NSPropertyListSerialization propertyListFromData:data 
																		 mutabilityOption:NSPropertyListMutableContainersAndLeaves 
																			format:&format 
																		 errorDescription:nil];
	// resource folder may be empty
	if (!resourceDict) {
		//MLogInfo(@"Cannot load resource dictionary: %@", path);
		return nil;
	}
		
	// get resources.
	for (NSDictionary *dict in [resourceDict objectForKey:self.resourcesPlistKey]) {
		MGSResourceItem *resource = [self.resourceClass resourceWithDictionary:dict];
		[self addResource_:resource];
	}
	[self.resources sortUsingSelector:@selector(caseInsensitiveNameCompare:)];
	
	self.defaultResourceID = [resourceDict objectForKey:@"DefaultID"];
	
	return resourceDict;
}

/*
 
 - makeResourcePath
 
 */
- (NSString *)makeResourcePath
{	
	// make template path
	NSString *name = [MGSPath validateFilenameCharacters:self.resourceName];
	NSString *path = [self.managerPath stringByAppendingPathComponent:name];
	path = [path stringByAppendingPathComponent:self.resourceFolder];
	
	return path;
}

/*
 
 - allResources
 
 */
- (NSMutableArray *)allResources
{
	// get resources
	NSMutableArray *allResources = [self.resources copy];
	
	// get descendent resources
	for (MGSResourcesManager *resourcesManager in self.resourcesManagers) {
		[allResources addObjectsFromArray:[resourcesManager allResources]];
	}
	
	return allResources;
}


/*
 
 - resourceClass
 
 */
- (Class)resourceClass
{
	//NSAssert(NO, @"abstract");
	
	return nil;
}


#pragma mark -
#pragma mark Node image

/*
 
 - defaultNodeImage
 
 */
- (NSImage *)defaultNodeImage
{
	return nil;
}

/*
 
 - originImage
 
 */
- (NSImage *)originImage
{
	MGSOriginTransformer *transformer = [[MGSOriginTransformer alloc] init];
	return [transformer transformedValue:self.origin];
}

#pragma mark -
#pragma mark Resource tree
/*
 
 - addToTree:
 
 */
- (void)addToTree:(MGSResourceBrowserNode *)parentNode
{
	if (self.resourcesManagers && [self.resourcesManagers count] > 0) {
		[self.resourcesManagers makeObjectsPerformSelector:_cmd withObject:parentNode];	
	} else {
		
		MGSResourceBrowserNode *node = self.managerNode;
		[[parentNode mutableChildNodes] addObject:node];

	}
}

/*
 
 - nodeName
 
 */
- (NSString *)nodeName
{
	return @"untitled";
}

#pragma mark -
#pragma mark Resource ID

/*
 
 - nextResourceID
 
 */
- (NSNumber *)nextResourceID
{
	NSNumber *lastID = nil;
	
	// array of numeric ID
	NSArray *IDs = [self.resources valueForKey:@"ID"];
	if ([IDs count] > 0) {
		IDs = [IDs sortedArrayUsingSelector:@selector(compare:)];
		lastID = [IDs lastObject];
	} else {
		lastID = [NSNumber numberWithInteger:0];
	}
	
	return [NSNumber numberWithInteger: [lastID integerValue] + 1];
}

#pragma mark -
#pragma mark NSCopying 

/*
 
 - copyWithZone:
 
 */
- (id)copyWithZone:(NSZone *)zone
{
#pragma unused(zone)
	
	MGSResourcesManager *copy = [[[self class] alloc] initWithPath:self.managerPath 
													name:self.resourceName 
													folder:self.resourceFolder];
	copy.delegate = self.delegate;
	copy.origin = self.origin;
	
	return copy;
}

#pragma mark -
#pragma mark Plist 
/*
 
 - plistName
 
 */
- (NSString *)plistName
{
	
	return @"resources.plist";
}

/*
 
 - resourceItemsPlistKey
 
 */
- (NSString *)resourcesPlistKey
{
	
	return @"Resources";
}

/*
 
 - plistRepresentation
 
 */
- (NSMutableDictionary *)plistRepresentation
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:5];
		
	// create array of resource plist
	NSMutableArray *resourceArray = [NSMutableArray arrayWithCapacity:10];
	for (MGSResourceItem *resource in self.resources) {
		[resourceArray addObject:[resource plistRepresentation]];
	}
	
	// resources
	[dict setObject:resourceArray forKey:self.resourcesPlistKey];
	
	// default ID
	[dict setObject:[self defaultResourceID] forKey:@"DefaultID"];

	return dict;
}

/*
 
 - save
 
 */
- (BOOL)save
{
	NSString *path = [self.resourcePath stringByAppendingPathComponent:[self plistName]];
	
	return [[self plistRepresentation] writeToFile:path atomically:YES];
}
/*
 
 - pathToResource:type:
 
 */
- (NSString *)pathToResource:(MGSResourceItem *)resource type:(MGSResourceItemFileType)resourceType
{
	// find path to template file
	NSString *path = self.resourcePath;
	path = [path stringByAppendingPathComponent:[resource.ID stringValue]];
	NSString *extension = nil;
	
	switch (resourceType) {
		case MGSResourceItemTextFile:
			extension = @"txt";
			break;

		case MGSResourceItemMarkdownFile:
			extension = @"mdtxt";
			break;
			
		case MGSResourceItemRTFDFile:
			extension = @"rtfd";
			break;

		case MGSResourceItemPlistFile:
			extension = @"plist";
			break;
			
		default:
			MLogInfo(@"invalid resource type");
			return nil;
	}
	
	path = [path stringByAppendingPathExtension:extension];
	
	return path;
}

@end
