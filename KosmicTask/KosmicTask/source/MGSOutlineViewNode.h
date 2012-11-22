//
//  MGSOutlineViewNode.h
//  Mother
//
//  Created by Jonathan on 22/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MGSOutlineViewNode : NSTreeNode {
	BOOL _isDraggable;
	NSImage *_image;
	NSInteger _count;
	BOOL _hasCount;
	NSColor *_countColor;
	NSImage *_statusImage;
	BOOL _countChildNodes;
	NSDictionary *_options;
	NSString *_type;
    BOOL _updating;
    NSUInteger _updatingImageIndex;
}
+ (void)registerClass:(Class)klass options:(NSDictionary *)options;
- (MGSOutlineViewNode *)createChildNodeWithRepresentedObject:(id)model;
- (void)removeChildNodeWithName:(NSString *)name;
- (id)ancestorNodeWithRepresentedClass:(Class)klass;
- (id)descendantNodeWithRepresentedClass:(Class)klass;
- (id)descendantNodeWithRepresentedObject:(id)object;
- (id)descendantNodeWithName:(NSString *)aName;
- (void)representedObjectDidChange;
//- (void)setRepresentedObjectValue:(id)value forKey:(NSString *)key;
- (id)childNodeWithName:(NSString *)aName;
- (void)sortNameRecursively:(BOOL)recursively;
- (void)sortWithKey:(NSString *)key recursively:(BOOL)recursively;
- (NSString *)name;
- (void)insertObject:(MGSOutlineViewNode *)node sortedBy:(NSString *)sortBy;
- (void)removeChildNodeWithRepresentedObject:(id)object;
- (void)removeFromParent;

@property BOOL isDraggable;
@property (assign) NSImage *image;
@property (copy) NSImage *statusImage;
@property NSInteger count;
@property BOOL hasCount;
@property (copy) NSColor *countColor;
@property BOOL countChildNodes;
@property (copy) NSDictionary *options;
@property (copy) NSString *type;
@property (getter=isUpdating) BOOL updating;
@property NSUInteger updatingImageIndex;

@end
