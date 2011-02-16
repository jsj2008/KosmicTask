//
//  MGSToggleButton.h
//  Mother
//
//  Created by Jonathan on 04/02/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MGSToggleButton : NSButton {
	NSImage *_onStateImage;
	NSImage *_onStateAltImage;
	NSImage *_onStateDisabledImage;
	
	NSImage *_offStateImage;
	NSImage *_offStateAltImage;
	NSImage *_offStateDisabledImage;
	
	NSImage *_mixedStateImage;
	NSImage *_mixedStateAltImage;
	NSImage *_mixedStateDisabledImage;
	
	NSInteger _state;
}

@property (assign) NSImage *onStateImage;
@property (assign) NSImage *onStateAltImage;
@property (assign) NSImage *onStateDisabledImage;
@property (assign) NSImage *offStateImage;
@property (assign) NSImage *offStateAltImage;
@property (assign) NSImage *offStateDisabledImage;
@property (assign) NSImage *mixedStateImage;
@property (assign) NSImage *mixedStateAltImage;
@property (assign) NSImage *mixedStateDisabledImage;

@property NSInteger state;

@end
