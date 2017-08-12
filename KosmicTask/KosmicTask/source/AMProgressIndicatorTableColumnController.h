//
//  AMProgressIndicatorTableColumnController.h
//  IPICellTest
//
//  Created by Andreas on 23.01.07.
//  Copyright 2007 Andreas Mayer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// making this a subclass of NSTableColumn seemed to muck up
// dragging of table columns
@interface AMProgressIndicatorTableColumnController : NSObject {
	NSTableColumn *__weak tableColumn;
	NSTimer *heartbeatTimer;
}

@property (weak, readonly) NSTableColumn *tableColumn;
- (id)initWithTableColumn:(NSTableColumn *)column;

- (void)startAnimation;

- (void)stopAnimation;


@end
