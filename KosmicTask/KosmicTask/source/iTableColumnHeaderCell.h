//
//  iTableColumnHeaderCell.h
//  iTableColumnHeader
//
//  Created by Matt Gemmell on Thu Feb 05 2004.
//  <http://iratescotsman.com/>
//

#import <Cocoa/Cocoa.h>


@interface iTableColumnHeaderCell : NSTableHeaderCell {
    //NSImage *metalBg;
    NSMutableDictionary *attrs;
	int _sortPriority;
	BOOL _sortAscending;
}

-(void)setSortAscending:(BOOL)asc priority:(int)pri;
@end
