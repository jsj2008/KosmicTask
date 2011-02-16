//
//  MGSFilledView.h
//  Mother
//
//  Created by Jonathan on 27/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MGSFilledView : NSView {
	NSColor *_fillColor;
}
@property (copy) NSColor *fillColor;
@end
