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

@property (strong) NSImage *onStateImage;
@property (strong) NSImage *onStateAltImage;
@property (strong) NSImage *onStateDisabledImage;
@property (strong) NSImage *offStateImage;
@property (strong) NSImage *offStateAltImage;
@property (strong) NSImage *offStateDisabledImage;
@property (strong) NSImage *mixedStateImage;
@property (strong) NSImage *mixedStateAltImage;
@property (strong) NSImage *mixedStateDisabledImage;

@property (nonatomic) NSInteger state;

@end
