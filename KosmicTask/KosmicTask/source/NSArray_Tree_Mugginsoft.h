//
//  NSArray_Tree_Mugginsoft.h
//  KosmicTask
//
//  Created by Jonathan on 22/12/2009.
//  Copyright 2009 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSArray(NSArray_Tree_Mugginsoft)

+ (NSArray *)arrayTreeWithObject:(id)object;
+ (NSArray *)addToArrayTree:(id)resultObject withParent:(NSTreeNode *)parentNode;

@end
