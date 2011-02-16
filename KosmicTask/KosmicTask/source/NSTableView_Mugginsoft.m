//
//  NSTableView_Mugginsoft.m
//  Mother
//
//  Created by Jonathan on 19/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "NSTableView_Mugginsoft.h"
#import "iTableColumnHeaderCell.h"

@implementation NSTableView(Mugginsoft)

/*
 
 set grdient header cells
 
 */
- (void)setGradientHeaderCells
{
	
	NSArray *columns = [self tableColumns];
	NSEnumerator *cols = [columns objectEnumerator];
	NSTableColumn *col = nil;
	
	iTableColumnHeaderCell *iHeaderCell;
	
	// note that the table header cell cannot be set in IB
	// thus much of the functionality that IB sets up between the table
	// columns and the header is lost.
	// so this functionality has to be recreated
	// even pointing the isa of the headercell to iTableColumnHeaderCell doesn't work
	while ((col = [cols nextObject])) {
		iHeaderCell = [[iTableColumnHeaderCell alloc] 
					   initTextCell:[[col headerCell] stringValue]];
		[col setHeaderCell:iHeaderCell];
		[iHeaderCell release];
	}
}

/*
 
 reload data for selected row
 
 */
- (void)reloadDataForSelectedRow
{
	NSInteger row = [self selectedRow];
	if (row == -1) return;
	
	[self setNeedsDisplayInRect:[self rectOfRow:row]];
	[self displayIfNeeded];
}
@end
