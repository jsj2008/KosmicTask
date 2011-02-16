//  NSTreeController-DMExtensions.h
//  Library
//
//  Created by William Shipley on 3/10/06.
//  Copyright 2006 Delicious Monster Software, LLC. Some rights reserved,
//    see Creative Commons license on wilshipley.com

#import <Cocoa/Cocoa.h>

@interface NSTreeController (MGS_Extensions)
- (void)mgs_processOutlineView:(NSOutlineView *)outlineView node:(id)node options:(NSSet *)options;
-(NSTreeNode *)mgs_outlineItemForObject:(id)object;
@end

@interface NSTreeController (DMExtensions)
- (void)dm_setSelectedObjects:(NSArray *)newSelectedObjects;
- (NSIndexPath *)dm_indexPathToObject:(id)object;
@end
