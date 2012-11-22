//
//  MGSOutlineViewNode.m
//  Mother
//
//  Created by Jonathan on 22/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSOutlineViewNode.h"
#import "MGSImageAndTextCell.h"

char MGSChildNodeContext;

static NSMutableDictionary *registeredClasses = nil;

// class extension
@interface MGSOutlineViewNode ()
- (id)_descendantNodeWithName:(NSString *)aName;
@end

@implementation MGSOutlineViewNode

@synthesize isDraggable = _isDraggable;
@synthesize image = _image;
@synthesize count = _count;
@synthesize hasCount = _hasCount;
@synthesize countColor = _countColor;
@synthesize statusImage = _statusImage;
@synthesize countChildNodes = _countChildNodes;
@synthesize options = _options;
@synthesize type = _type;
@synthesize updating = _updating;
@synthesize updatingImageIndex = _updatingImageIndex;

/*
 
 + keyPathsForValuesAffectingValueForKey:
 
 */
+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    if ([key isEqualToString:@"bindingObject"])
    {
        NSSet *affectingKeys = [NSSet setWithObjects:@"name", @"image", @"count", @"hasCount", @"countColor", @"statusImage", @"updating", @"updatingImageIndex", nil];
        keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKeys];
    }
    return keyPaths;
}


/*
 
 + registerClass:options:
 
 */
+ (void)registerClass:(Class)klass options:(NSDictionary *)options
{
	if (!registeredClasses) {
		registeredClasses = [NSMutableDictionary dictionaryWithCapacity:5];
	}
	NSMutableDictionary *mutableOptions = [registeredClasses objectForKey:[klass description]];
	if (mutableOptions) {
		[mutableOptions addEntriesFromDictionary:options];
	} else {
		mutableOptions = [NSMutableDictionary dictionaryWithDictionary:options];
		[registeredClasses setObject:mutableOptions forKey:[klass description]];
	}
	
}


/*
 
 - initWithRepresentedObject:
 
 */
- (id)initWithRepresentedObject:(id)model
{
	if ((self = [super initWithRepresentedObject:model])) {		
		_isDraggable = NO;
		_count = 0;
		_hasCount = NO;
		_countColor = [[MGSImageAndTextCell countColor] copy];
		_countChildNodes = NO;
	}
	return self;
}



/*
 
 - createChildNode
 
 */
- (MGSOutlineViewNode *)createChildNodeWithRepresentedObject:(id)model
{
	MGSOutlineViewNode *node = [[[self class] alloc] initWithRepresentedObject:model];
	[[self mutableChildNodes] addObject:node];
	return node;
}

/*
 
 - removeChildNodeWithName:
 
 */
- (void)removeChildNodeWithName:(NSString *)name
{
	MGSOutlineViewNode *matchedNode = nil;
	
	for (MGSOutlineViewNode *item in [self mutableChildNodes]) {
		if ([item.name isEqualToString:name]) {
			matchedNode = item;
			break;
		}
	}
	
	if (matchedNode) {
		[[self mutableChildNodes] removeObject:matchedNode];
	}
	
}

/*
 
 - removeChildNodeWithRepresentedObject:
 
 */
- (void)removeChildNodeWithRepresentedObject:(id)object
{
	for (MGSOutlineViewNode *node in [[self mutableChildNodes] copy]) {
		if (node.representedObject == object) {
			[[self mutableChildNodes] removeObject:node];			
			break;
		}
	}

}

/*
 
 - sortNameRecursively:
 
 */
- (void)sortNameRecursively:(BOOL)recursively
{
	static NSArray *descriptors = nil;
	if (!descriptors) {
		descriptors = [NSArray arrayWithObjects:
					   [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)],
					   nil];
	}
	[self sortWithSortDescriptors:descriptors recursively:recursively];
}

/*
 
 - sortWithKey:recursively:
 
 */
- (void)sortWithKey:(NSString *)key recursively:(BOOL)recursively
{
	NSArray *descriptors = [NSArray arrayWithObjects:
						[NSSortDescriptor sortDescriptorWithKey:key ascending:YES selector:@selector(caseInsensitiveCompare:)],
						nil];
	[self sortWithSortDescriptors:descriptors recursively:recursively];
}

/*
 
 - sortWithSortDescriptors:recursively:
 
 the native implementation of this must be broken.
 see http://code.google.com/p/amber-framework/source/browse/trunk/AmberKit/AFSourceNode.m?r=360
 
 */
- (void)sortWithSortDescriptors:(NSArray *)sortDescriptors recursively:(BOOL)recursively {
	[[self mutableChildNodes] setArray:[[self childNodes] sortedArrayUsingDescriptors:sortDescriptors]];
	if (recursively) for (NSTreeNode *currentNode in [self childNodes]) [currentNode sortWithSortDescriptors:sortDescriptors recursively:recursively];
}

/*
 
 - insertObject:sortedBy:
 
 */
- (void)insertObject:(MGSOutlineViewNode *)node sortedBy:(NSString *)sortBy
{
	NSString *insertValue = [node valueForKey:sortBy];
	NSAssert([insertValue isKindOfClass:[NSString class]], @"bad class");
	
	NSUInteger idx = 0;
	for (idx = 0; idx < [[self mutableChildNodes] count]; idx++) {
		id childNode = [[self mutableChildNodes] objectAtIndex:idx];
		NSString *childValue = [childNode valueForKey:sortBy];
		NSAssert([childValue isKindOfClass:[NSString class]], @"bad class");
		
		if ([childValue caseInsensitiveCompare:insertValue] == NSOrderedDescending) {
			break;
		}
	}
	
	[[self mutableChildNodes] insertObject:node atIndex:idx];
}

/*
 
 - removeFromParent
 
 */
- (void)removeFromParent
{
	[[[self parentNode] mutableChildNodes] removeObject:self];

}
#pragma mark -
#pragma mark KVO

/*
 
 - observeValueForKeyPath:ofObject:change:context
 
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
#pragma unused(change)
#pragma unused(context)
	
	if (context == &MGSChildNodeContext) {
		if (self.hasCount && self.countChildNodes) {
			self.count = [[self childNodes] count];
		}
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
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
	NSDictionary *options = [registeredClasses objectForKey:[objectClass description]];
	
	if (options) {
		NSString *key = [options objectForKey:optionKey];
		if (key) {
			return [self.representedObject valueForKey:key];
		}
	} 
	
	return nil;
}

/*
 
 - representedObjectDidChange
 
 */
- (void)representedObjectDidChange
{
	[self willChangeValueForKey:@"bindingObject"];
	[self didChangeValueForKey:@"bindingObject"];
}

/*
 
 - setRepresentedObjectValue:
 
 */
/*
- (void)setRepresentedObjectValue:(id)value forKey:(NSString *)key
{
	[self.representedObject setValue:value forKey:key];
	[self representedObjectDidChange];
}
*/
#pragma mark -
#pragma mark Accessors

/*
 
 - setCountChildNodes:
 
 */
- (void)setCountChildNodes:(BOOL)value
{
	if (_countChildNodes && value) return;
	if (_countChildNodes && !value) {
		[self removeObserver:self forKeyPath:@"childNodes"];
	}
	
	_countChildNodes = value;	
	if (_countChildNodes) {
		[self addObserver:self forKeyPath:@"childNodes" options:0 context:&MGSChildNodeContext];
	}
}
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
		} else if ([self.representedObject valueForKey:@"name"]) {
			name = [self.representedObject valueForKey:@"name"];
		} else if ([self.representedObject respondsToSelector:@selector(stringValue)]) {
			name = [self.representedObject performSelector:@selector(stringValue)];
		} else if ([self.representedObject respondsToSelector:@selector(description)]) {
			name = [self.representedObject performSelector:@selector(description)];
		} else {
			name = NSLocalizedString(@"untitled", @"MGSOutlineViewNode browser node default title");
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
		description = NSLocalizedString(@"-", @"MGSOutlineViewNode node default description");
	}
	
	return description;
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

/*
 
 - descendantNodeWithRepresentedClass:
 
 */
- (id)descendantNodeWithRepresentedClass:(Class)klass
{
	if ([[self representedObject] isKindOfClass: klass]) return self;
	
	for (MGSOutlineViewNode *node in [self childNodes]) {
		id found = nil;
		if ((found = [node descendantNodeWithRepresentedClass:klass])) {
			return found;
		}
	}
	
	return nil;
	
}

/*
 
 - descendantNodeWithRepresentedObject:
 
 */
- (id)descendantNodeWithRepresentedObject:(id)object
{
	if ([self representedObject] == object) return self;
	
	for (MGSOutlineViewNode *node in [self childNodes]) {
		id found = nil;
		if ((found = [node descendantNodeWithRepresentedObject:object])) {
			return found;
		}
	}
	
	return nil;
	
}

/*
 
 - descendantNodeWithName:
 
 */
- (id)descendantNodeWithName:(NSString *)aName
{ 
	 for (MGSOutlineViewNode *node in [self childNodes]) {
		 id found = nil;
		 if ((found = [node _descendantNodeWithName:aName])) {
			 return found;
		 }
	 }
	 
	 return nil;
}
/*

- descendantNodeWithName:

*/
- (id)_descendantNodeWithName:(NSString *)aName
{
	if ([[self name] isEqualTo:aName]) return self;

	for (MGSOutlineViewNode *node in [self childNodes]) {
		id found = nil;
		if ((found = [node _descendantNodeWithName:aName])) {
			return found;
		}
	}

	return nil;
}

/*
 
 - childNodeWithName:
 
 */
- (id)childNodeWithName:(NSString *)aName
{
	for (MGSOutlineViewNode *node in [self childNodes]) {
		if ([node.name isEqualToString:aName]) {
			return node;
		}
	}
	
	return nil;
}

@end
