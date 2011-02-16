//
//  MGSResourceOutlineView.h
//  KosmicTask
//
//  Created by Jonathan on 02/09/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol MGSResourceOutlineViewDelegate
-(NSInteger)mgs_outlineView:(NSOutlineView *)outlineview drawStyleForRow:(int)row;
@end

@interface MGSResourceOutlineView : NSOutlineView {

}

@end
