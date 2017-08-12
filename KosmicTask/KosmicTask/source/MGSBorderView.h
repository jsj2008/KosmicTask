//
//  MGSBorderView.h
//  KosmicTask
//
//  Created by Jonathan on 30/06/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

enum eMGSBorderViewFlags {
  kMGSBorderViewTop = 0x01,
  kMGSBorderViewRight = 0x02,
  kMGSBorderViewBottom = 0x04,
  kMGSBorderViewLeft = 0x08
};
typedef NSUInteger MGSBorderViewFlags;

@interface MGSBorderView : NSView {
    NSColor *_borderColor;
    MGSBorderViewFlags _borderFlags;
}

@property (strong) NSColor *borderColor;
@property (assign) MGSBorderViewFlags borderFlags;

@end
