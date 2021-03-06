//
//  MGSToolbarItem.h
//  KosmicTask
//
//  Created by Jonathan on 01/01/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol MGSToolbarItemDelegate <NSObject>
@optional
- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem;
@end

@interface MGSToolbarItem : NSToolbarItem {
	id delegate;
}

@property (assign) id <MGSToolbarItemDelegate> delegate;
@end
