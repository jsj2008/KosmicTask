//
//  NSOutlineView_Mugginsoft.h
//  KosmicTask
//
//  Created by Jonathan on 01/09/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSOutlineView (Mugginsoft)

- (void)mgs_expandAll;
- (void)mgs_collapseAll;
- (NSMutableArray *)mgs_expandableItems;

@end
