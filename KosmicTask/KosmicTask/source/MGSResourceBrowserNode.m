//
//  MGSResourceBrowserNode.m
//  KosmicTask
//
//  Created by Jonathan on 14/06/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSResourceBrowserNode.h"
#import "MGSResourceItem.h"

static NSMutableDictionary *registeredClasses = nil;

@implementation MGSResourceBrowserNode

@synthesize image, counter, hasCount, statusImage;

/*
 
 + keyPathsForValuesAffectingValueForKey:
 
 */
+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    if ([key isEqualToString:@"bindingObject"])
    {
        NSSet *affectingKeys = [NSSet setWithObjects:@"name", @"image", @"counter", @"hasCount", @"statusImage", nil];
        keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKeys];
    }
    return keyPaths;
}


/*
 
 + initialize
 
 */
+ (void)initialize
{
	
}

/*
 
 + registerClass:options:
 
 */
+ (void)registerClass:(Class)klass options:(NSDictionary *)options
{
	if (!registeredClasses) {
		registeredClasses = [NSMutableDictionary dictionaryWithCapacity:5];
	}
	NSMutableDictionary *mutableOptions = [registeredClasses objectForKey:klass];
	if (mutableOptions) {
		[mutableOptions addEntriesFromDictionary:options];
	} else {
		mutableOptions = [NSMutableDictionary dictionaryWithDictionary:options];
		[registeredClasses setObject:mutableOptions forKey:klass];	
	}

}

/*
 
 - initWithRepresentedObject:
 
 */
- (id)initWithRepresentedObject:(id)modelObject
{
	self = [super initWithRepresentedObject:modelObject];
	if (self) {
		self.counter = 0;
		hasCount = NO;
	}
	return self;
}

#pragma mark -
#pragma mark Binding support

/*
 
 - bindingObject
 
 */
- (id)bindingObject
{
	return self;
}

/*
 
 - objectForKey:
 
 */
- (id)objectForKey:(id)optionKey
{
	Class objectClass = [self.representedObject class];
	NSDictionary *options = [registeredClasses objectForKey:objectClass];
	
	if (options) {
		NSString *key = [options objectForKey:optionKey];
		if (key) {
			return [self.representedObject valueForKey:key];
		}
	} 
	
	return nil;
}


#pragma mark -
#pragma mark Accessors

/*
 
 - name
 
 */
- (NSString *)name
{
	NSString *name = [self objectForKey:@"name"];
	
	if (!name) {
		if ([self.representedObject isKindOfClass:[NSString class]]) {
			name = self.representedObject;
		} else if ([self.representedObject respondsToSelector:@selector(name)]) {
			name = [self.representedObject performSelector:@selector(name)];
		} else if ([self.representedObject respondsToSelector:@selector(stringValue)]) {
			name = [self.representedObject performSelector:@selector(stringValue)];
		} else if ([self.representedObject respondsToSelector:@selector(description)]) {
			name = [self.representedObject performSelector:@selector(description)];
		} else {
			name = NSLocalizedString(@"untitled", @"resource browser node default title");
		}
	}

	return name;
}

/*
 
 - description
 
 */
- (NSString *)description
{
	NSString *description = [self objectForKey:@"description"];
	if (!description) {
		description = NSLocalizedString(@"-", @"resource browser node default description");
	}
	
	return description;
}

/*
 
 - subrootDescription
 
 */
- (NSString *)subrootDescription
{
	NSString *description = @"-";
	
	NSTreeNode *root = self;
	NSTreeNode *subRoot = nil;
	do {
		if (!root.parentNode) break;
		subRoot = root;
		root = subRoot.parentNode;
	} while (YES);
	
	if ([subRoot isKindOfClass:[self class]] || [subRoot respondsToSelector:@selector(name)]) {
		description = [(id)subRoot name];
	}
	return description;
}

/*
 
 - setCounter:
 
 */
- (void)setCounter:(NSInteger)value
{
	counter = value;
	count = [NSNumber numberWithInteger:value];
}

#pragma mark -
#pragma mark Tree support
/*
 
 - leaves
 
 */
- (NSMutableArray *)leaves
{
	NSMutableArray *leaves = [NSMutableArray arrayWithCapacity:10];
	if ([self isLeaf]) {
		if ([self.representedObject isKindOfClass:[MGSResourceItem class]]) {
			[leaves addObject:self];
		}
	} else {
		for (MGSResourceBrowserNode *node in [self childNodes]) {
			if ([node respondsToSelector:@selector(leaves)]) {
				[leaves addObjectsFromArray:[node leaves]];
			}
		}
	}
	
	return leaves;
}

/*
 
 - ancestorNodeWithRepresentedClass:
 
 */
- (id)ancestorNodeWithRepresentedClass:(Class)klass
{
	NSTreeNode *node = self;
	
	while (YES) {
		node = [node parentNode];
		if (!node) {
			return nil;
		}
		if ([[node representedObject] isKindOfClass:klass]) {
			break;
		}
	}
	
	return node;
	
}

#pragma mark -
#pragma mark Sorting

/*
 
 - compare:
 
 */
- (NSComparisonResult)compare:(MGSResourceBrowserNode *)node
{
	return [[self name] compare:[node name]];
}

#pragma mark -
#pragma mark NSCopying
/*
 
 - copyWithZone:
 
 */
- (id)copyWithZone:(NSZone *)zone
{
	#pragma unused(zone)
	
	id repObject = self.representedObject;
	if ([repObject conformsToProtocol:@protocol(NSCopying)]) {
		repObject = [repObject copy];
	}
	MGSResourceBrowserNode *theCopy = [[[self class] alloc] initWithRepresentedObject:repObject];
	theCopy.image = [self.image copy];
	//theCopy.count = self.count;
	theCopy.counter = self.counter;
	theCopy.hasCount = self.hasCount;
	theCopy.statusImage = self.statusImage;
	
	
	for (id item in [self mutableChildNodes]) {
		if ([item conformsToProtocol:@protocol(NSCopying)]) {
			[[theCopy mutableChildNodes] addObject:[item copy]];
		}
	}
	return theCopy;
}
@end
