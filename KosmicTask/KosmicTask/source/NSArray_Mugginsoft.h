//
//  NSArray_Mugginsoft.h
//  KosmicTask
//
//  Created by Jonathan on 03/04/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSArray (Mugginsoft)
- (NSArray *)mgs_sortedArrayUsingBestSelector;
- (NSArray *)mgs_sortedArrayUsingSelectors:(NSArray *)selectors;
- (BOOL)mgs_objectsShareClass;
- (NSDictionary *)mgs_objectIndexes;
@end
