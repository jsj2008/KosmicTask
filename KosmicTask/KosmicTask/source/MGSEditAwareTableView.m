//
//  MGSEditAwareTableView.m
//  KosmicTask
//
//  Created by Jonathan on 06/04/2013.
//
//

#import "MGSEditAwareTableView.h"

@implementation MGSEditAwareTableView

/*
 
 - awakeFromNib
 
 */
- (void)awakeFromNib
{
    //self.backgroundColor = [NSColor colorWithCatalogName:@"System"colorName:@"_sourceListBackgroundColor"];
    
    //self.backgroundColor = [NSColor colorWithDeviceRed:0.0f green: 0.0f blue: 0.0f alpha: 0.02f];
    
}

/*
 
 drawRow:clipRect;
 
 see http://www.corbinstreehouse.com/blog/archives/cocoa/
 
 */
- (void)drawRow:(NSInteger)row clipRect:(NSRect)clipRect
{    
	MGSTableViewRowDrawStyle drawStyleForRow = kMGSTableViewRowEditAware;
	
	// ask delegate about drawRowStyle
	if (self.delegate && [self.delegate respondsToSelector:@selector(mgs_tableView:drawStyleForRow:)]) {
		drawStyleForRow = [(id)self.delegate mgs_tableView:self drawStyleForRow:row];
	}
	
	NSRect rect = NSZeroRect;
	
	// using this method we can draw the entire row backround and then let the cells draw over it
	switch (drawStyleForRow) {
            
		case kMGSTableViewRowEditAware:
        {
            [[NSColor colorWithDeviceRed:0.0f green: 0.0f blue: 0.0f alpha: 0.05f] set];
            for (NSUInteger col = 0; col < [self.tableColumns count]; col++) {
                NSTableColumn *tableColumn = [self.tableColumns objectAtIndex:col];
                if (!tableColumn.isEditable) {
                    rect = [self frameOfCellAtColumn:col row:row];
                    rect = NSInsetRect(rect, -self.intercellSpacing.width/2, -self.intercellSpacing.height/2);
                    [NSBezierPath fillRect:rect];
               }
             }
        }
			break;
			
		default:
			NSAssert(NO, @"invalid switch value");
	}
	
	[super drawRow:row clipRect:clipRect];
}


@end
