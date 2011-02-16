//
//  MGSCollapsibleSplitView.h
//  KosmicTask
//
//  Created by Jonathan on 15/10/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MGSCollapsibleSplitView : NSSplitView {
	NSMutableDictionary *_collapsedSubviewsDict;
}

- (void)collapseSubviewAt:(int)offset;
- (void)uncollapseSubviewAt:(int)offset;

@end
