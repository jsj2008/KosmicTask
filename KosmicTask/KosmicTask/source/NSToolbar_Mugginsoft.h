//
//  NSToolbar_Mugginsoft.h
//  Mother
//
//  Created by Jonathan on 01/03/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSToolbar (Mugginsoft)
- (int)indexOfItemWithItemIdentifier:(NSString *)identifier;
- (void)removeItemWithItemIdentifier:(NSString *)identifier;
- (void)removeItemsStartingAtIndex:(NSInteger)startIndex;
@end
