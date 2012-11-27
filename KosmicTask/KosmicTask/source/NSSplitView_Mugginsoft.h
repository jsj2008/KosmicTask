//
//  MGSViewBehaviour.h
//  Mother
//
//  Created by Jonathan on 31/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>


enum _MGSSplitviewBehaviour {
	MGSSplitviewBehaviourNone = -1,
	MGSSplitviewBehaviourOf2ViewsFirstFixed = 0,			// 2 views - first fixed width
	MGSSplitviewBehaviourOf2ViewsSecondFixed,				// 2 views - second fixed width
	MGSSplitviewBehaviourOf3ViewsFirstAndSecondFixed,		//  3 views - first and second fixed width	
	MGSSplitviewBehaviourOf3ViewsFirstAndThirdFixed,		//  3 views - first and third fixed width
};
typedef NSInteger MGSSplitviewBehaviour;

@interface NSSplitView(Mugginsoft)
- (void)resizeSubviewsWithOldSize: (NSSize)oldSize withBehaviour:(MGSSplitviewBehaviour)behaviour;
- (void)resizeSubviewsWithOldSize:(NSSize)oldSize withBehaviour:(MGSSplitviewBehaviour)behaviour minSizes:(NSArray *)minSizes;
- (void)logSubviewFrames;
//- (void)replaceSubview:(NSView *)oldView withViewSizedAsOld:(NSView *)newView;
- (void)restoreSubviewFramesWithDefaultsName:(NSString *)name;
- (void)saveSubviewFramesWithDefaultsName:(NSString *)name;
@end
