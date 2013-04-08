//
//  MGSEditAwareTableView.h
//  KosmicTask
//
//  Created by Jonathan on 06/04/2013.
//
//

#import <Cocoa/Cocoa.h>

enum {
    kMGSTableViewRowEditAware = 0
};
typedef NSInteger MGSTableViewRowDrawStyle;

@protocol MGSEditAwareTableViewDelegate
-(MGSTableViewRowDrawStyle)mgs_tableView:(NSTableView *)outlineview drawStyleForRow:(NSInteger)row;
@end

@interface MGSEditAwareTableView : NSTableView

@end
