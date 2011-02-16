//
//  NSColor_Mugginsoft.h
//  KosmicQuitter
//
//  Created by Jonathan on 03/01/2009.
//  Copyright 2009 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSColor (Mugginsoft)

-(NSColor *)colorWithLighting:(float)light;
-(NSColor *)colorWithLighting:(float)light plasticity:(float)plastic;

@end
