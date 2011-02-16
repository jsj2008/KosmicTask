//
//  MGSBrowserViewControlStrip.h
//  Mother
//
//  Created by Jonathan on 04/12/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSGradientView.h"

#define BROWSER_CLOSE_SEGMENT_INDEX 0
#define BROWSER_TASK_SEGMENT_INDEX 1
#define BROWSER_SEARCH_SEGMENT_INDEX 2
#define BROWSER_SHARING_SEGMENT_INDEX 3

#define BROWSER_MIN_SEGMENT_INDEX BROWSER_CLOSE_SEGMENT_INDEX
#define BROWSER_MAX_SEGMENT_INDEX BROWSER_SHARING_SEGMENT_INDEX

@protocol MGSBrowserViewControlStrip
- (void)browserSegControlClicked:(id)sender;
@end

@interface MGSBrowserViewControlStrip : MGSGradientView {
	IBOutlet NSView *_centreView;
	IBOutlet NSView *_leftView;
	IBOutlet id _delegate;
	IBOutlet NSSegmentedControl *_viewSelectorSegmentedControl; 
	NSInteger _prevClickedSegment;
	NSInteger _segmentToSelectWhenNotHidden;
	BOOL browserViewVisible;
	IBOutlet NSView *leftAttachedView;
	IBOutlet NSButton *sidebarToggle;
	IBOutlet NSButton *groupToggle;
}

- (IBAction)segControlClicked:(id)sender;
- (IBAction)sidebarToggleAction:(id)sender;
- (IBAction)groupToggleAction:(id)sender;
- (void)selectSegment:(NSInteger)index;
@end
