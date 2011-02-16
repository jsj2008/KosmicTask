//
//  NSColor_Mugginsoft.m
//  KosmicQuitter
//
//  Created by Jonathan on 03/01/2009.
//  Copyright 2009 mugginsoft.com. All rights reserved.
//

#import "NSColor_Mugginsoft.h"


@implementation NSColor (Mugginsoft)

/*
 
 color with lighting
 
 */
-(NSColor *)colorWithLighting:(float)light
{
	return [self colorWithLighting:light plasticity:0];
}
/*
 
 color with lighting
 
 http://code.google.com/p/blacktree-alchemy/source/browse/trunk/Crucible/Code/NSColor_QSModifications.m
 
 */
-(NSColor *)colorWithLighting:(float)light plasticity:(float)plastic
{
	if (plastic>1)plastic=1.0;
	if (plastic<0)plastic=0.0;
	NSColor *color=[self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	float h,s,b,a;
	
	[color getHue:&h
	   saturation:&s brightness:&b alpha:&a];
	
	b+=light;
	color=[NSColor colorWithCalibratedHue:h
							   saturation:s
							   brightness:b
									alpha:a];	
	
	if (plastic){
		color=[color blendedColorWithFraction:plastic*light ofColor:
			   [NSColor colorWithCalibratedWhite:1.0 alpha:[color alphaComponent]]];
	}
	return color;
}

@end
