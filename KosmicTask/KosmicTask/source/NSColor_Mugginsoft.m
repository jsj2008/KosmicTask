//
//  NSColor_Mugginsoft.m
//  KosmicTask
//
//  Created by Jonathan on 07/04/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "NSColor_Mugginsoft.h"


#pragma mark -

/*
 
 http://source.colloquy.info/svn/trunk/Additions/NSColorAdditions.m
 
 
 this is GPL
 
 */
@implementation NSColor (Mugginsoft)

+ (NSColor *) mgs_colorWithHTMLAttributeValue:(NSString *) attribute {
	NSCharacterSet *hex = [NSCharacterSet characterSetWithCharactersInString:@"1234567890abcdefABCDEF"];
	NSScanner *scanner = [NSScanner scannerWithString:( [attribute hasPrefix:@"#"] ? [attribute substringFromIndex:1] : attribute )];
	NSString *code = nil;
	
	[scanner scanCharactersFromSet:hex intoString:&code];
	
	if( [code length] == 6 ) { // decode colors like #ffee33
		unsigned color = 0;
		scanner = [NSScanner scannerWithString:code];
		if( ! [scanner scanHexInt:&color] ) return nil;
		return [self colorWithCalibratedRed:( ( ( color >> 16 ) & 0xff ) / 255.f ) green:( ( ( color >> 8 ) & 0xff ) / 255.f ) blue:( ( color & 0xff ) / 255.f ) alpha:1.f];
	} else if( [code length] == 3 ) {  // decode short-hand colors like #fe3
		unsigned color = 0;
		scanner = [NSScanner scannerWithString:code];
		if( ! [scanner scanHexInt:&color] ) return nil;
		return [self colorWithCalibratedRed:( ( ( ( ( color >> 8 ) & 0xf ) << 4 ) | ( ( color >> 8 ) & 0xf ) ) / 255.f ) green:( ( ( ( ( color >> 4 ) & 0xf ) << 4 ) | ( ( color >> 4 ) & 0xf ) ) / 255.f ) blue:( ( ( ( color & 0xf ) << 4 ) | ( color & 0xf ) ) / 255.f ) alpha:1.f];
	} else if( ! [attribute hasPrefix:@"#"] ) {
		attribute = [attribute lowercaseString];
		if( [attribute hasPrefix:@"white"] ) return [self whiteColor];
		else if( [attribute hasPrefix:@"black"] ) return [self blackColor];
		else if( [attribute hasPrefix:@"gray"] ) return [self grayColor];
		else if( [attribute hasPrefix:@"aqua"] ) return [self cyanColor];
		else if( [attribute hasPrefix:@"blue"] ) return [self blueColor];
		else if( [attribute hasPrefix:@"yellow"] ) return [self yellowColor];
		else if( [attribute hasPrefix:@"lime"] ) return [self greenColor];
		else if( [attribute hasPrefix:@"fuchsia"] ) return [self magentaColor];
		else if( [attribute hasPrefix:@"red"] ) return [self redColor];
		else if( [attribute hasPrefix:@"silver"] ) return [self colorWithCalibratedRed:0.75f green:0.75f blue:0.75f alpha:1.f];
		else if( [attribute hasPrefix:@"maroon"] ) return [self colorWithCalibratedRed:0.5f green:0.f blue:0.f alpha:1.f];
		else if( [attribute hasPrefix:@"purple"] ) return [self colorWithCalibratedRed:0.5f green:0.f blue:0.5f alpha:1.f];
		else if( [attribute hasPrefix:@"green"] ) return [self colorWithCalibratedRed:0.f green:0.5f blue:0.f alpha:1.f];
		else if( [attribute hasPrefix:@"olive"] ) return [self colorWithCalibratedRed:0.5f green:0.5f blue:0.f alpha:1.f];
		else if( [attribute hasPrefix:@"navy"] ) return [self colorWithCalibratedRed:0.f green:0.f blue:0.5f alpha:1.f];
		else if( [attribute hasPrefix:@"teal"] ) return [self colorWithCalibratedRed:0.f green:0.5f blue:0.5f alpha:1.f];
	}
	
	return nil;
}

+ (NSColor *) mgs_colorWithCSSAttributeValue:(NSString *) attribute {
	NSColor *ret = [self mgs_colorWithHTMLAttributeValue:attribute];
	
	if( ! ret && [attribute hasPrefix:@"rgb"] ) {
		NSCharacterSet *whites = [NSCharacterSet whitespaceCharacterSet];
		BOOL hasAlpha = [attribute hasPrefix:@"rgba"];
		NSScanner *scanner = [NSScanner scannerWithString:attribute];
		[scanner scanCharactersFromSet:whites intoString:nil];
		if( [scanner scanUpToString:@"(" intoString:nil] ) {
			double red = 0., green = 0., blue = 0., alpha = 1.;
			BOOL redPercent = NO, greenPercent = NO, bluePercent = NO;
			[scanner scanString:@"(" intoString:nil];
			[scanner scanCharactersFromSet:whites intoString:nil];
			if( [scanner scanDouble:&red] ) {
				redPercent = [scanner scanString:@"%" intoString:nil];
				[scanner scanCharactersFromSet:whites intoString:nil];
				[scanner scanString:@"," intoString:nil];
				[scanner scanCharactersFromSet:whites intoString:nil];
				if( [scanner scanDouble:&green] ) {
					greenPercent = [scanner scanString:@"%" intoString:nil];
					[scanner scanCharactersFromSet:whites intoString:nil];
					[scanner scanString:@"," intoString:nil];
					[scanner scanCharactersFromSet:whites intoString:nil];
					if( [scanner scanDouble:&blue] ) {
						bluePercent = [scanner scanString:@"%" intoString:nil];
						[scanner scanCharactersFromSet:whites intoString:nil];
						red = MAX( 0., MIN( ( redPercent ? 100. : 255. ), red ) );
						green = MAX( 0., MIN( ( greenPercent ? 100. : 255. ), green ) );
						blue = MAX( 0., MIN( ( bluePercent ? 100. : 255. ), blue ) );
						if( hasAlpha ) {
							[scanner scanString:@"," intoString:nil];
							[scanner scanCharactersFromSet:whites intoString:nil];
							if( [scanner scanDouble:&alpha] ) {
								[scanner scanCharactersFromSet:whites intoString:nil];
								[scanner scanString:@")" intoString:nil];
								alpha = MAX( 0., MIN( 1., alpha ) );
								ret = [self colorWithCalibratedRed:(CGFloat)( redPercent ? red / 100.f : red / 255.f ) green:(CGFloat)( greenPercent ? green / 100.f : green / 255.f ) blue:(CGFloat)( bluePercent ? blue / 100.f : blue / 255.f ) alpha:(CGFloat)alpha];
							}
						} else {
							ret = [self colorWithCalibratedRed:(CGFloat)( redPercent ? red / 100. : red / 255. ) green:(CGFloat)( greenPercent ? green / 100.f : green / 255.f ) blue:(CGFloat)( bluePercent ? blue / 100.f : blue / 255.f ) alpha:1.f];
						}
					}
				}
			}
		}
	} else if( ! ret && [attribute hasPrefix:@"hsl"] ) {
		NSCharacterSet *whites = [NSCharacterSet whitespaceCharacterSet];
		BOOL hasAlpha = [attribute hasPrefix:@"hsla"];
		NSScanner *scanner = [NSScanner scannerWithString:attribute];
		[scanner scanCharactersFromSet:whites intoString:nil];
		if( [scanner scanUpToString:@"(" intoString:nil] ) {
			double hue = 0., saturation = 0., lightness = 0., alpha = 1.;
			[scanner scanString:@"(" intoString:nil];
			[scanner scanCharactersFromSet:whites intoString:nil];
			if( [scanner scanDouble:&hue] ) {
				[scanner scanCharactersFromSet:whites intoString:nil];
				[scanner scanString:@"," intoString:nil];
				[scanner scanCharactersFromSet:whites intoString:nil];
				if( [scanner scanDouble:&saturation] && [scanner scanString:@"%" intoString:nil] ) {
					[scanner scanCharactersFromSet:whites intoString:nil];
					[scanner scanString:@"," intoString:nil];
					[scanner scanCharactersFromSet:whites intoString:nil];
					if( [scanner scanDouble:&lightness] && [scanner scanString:@"%" intoString:nil] ) {
						[scanner scanCharactersFromSet:whites intoString:nil];
						hue = ( ( ( (long) hue % 360 ) + 360 ) % 360 );
						saturation = MAX( 0., MIN( 100., saturation ) );
						lightness = MAX( 0., MIN( 100., lightness ) );
						if( hasAlpha ) {
							[scanner scanString:@"," intoString:nil];
							[scanner scanCharactersFromSet:whites intoString:nil];
							if( [scanner scanDouble:&alpha] ) {
								[scanner scanCharactersFromSet:whites intoString:nil];
								[scanner scanString:@")" intoString:nil];
								alpha = MAX( 0., MIN( 1., alpha ) );
								ret = [self colorWithCalibratedHue:(CGFloat)( hue / 360.f ) saturation:(CGFloat)( saturation / 100.f ) brightness:(CGFloat)( lightness / 100.f ) alpha:(CGFloat)alpha];
							}
						} else {
							ret = [self colorWithCalibratedHue:(CGFloat)( hue / 360.f ) saturation:(CGFloat)( saturation / 100.f ) brightness:(CGFloat)( lightness / 100.f ) alpha:1.f];
						}
					}
				}
			}
		}
	} else if( ! ret && [attribute hasPrefix:@"transparent"] ) {
		ret = [self clearColor];
	}
	
	return ret;
}

- (NSString *) mgs_HTMLAttributeValue {
	CGFloat red = 0.f, green = 0.f, blue = 0.f;
	NSColor *color = self;
	if( ! [[self colorSpaceName] isEqualToString:NSDeviceRGBColorSpace] && ! [[self colorSpaceName] isEqualToString:NSCalibratedRGBColorSpace] )
		color = [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	[color getRed:&red green:&green blue:&blue alpha:NULL];
	return [NSString stringWithFormat:@"#%02X%02X%02X", (unsigned char)(red * 255.), (unsigned char)(green * 255.), (unsigned char)(blue * 255.)];
}

- (NSString *) mgs_CSSAttributeValue {
	CGFloat red = 0.f, green = 0.f, blue = 0.f, alpha = 0.f;
	NSColor *color = self;
	if( ! [[self colorSpaceName] isEqualToString:NSDeviceRGBColorSpace] && ! [[self colorSpaceName] isEqualToString:NSCalibratedRGBColorSpace] )
		color = [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	[color getRed:&red green:&green blue:&blue alpha:&alpha];
	if( alpha < 1. ) return [NSString stringWithFormat:@"rgba( %d, %d, %d, %.3f )", (unsigned char)(red * 255.), (unsigned char)(green * 255.), (unsigned char)(blue * 255.), alpha];
	return [NSString stringWithFormat:@"#%02X%02X%02X", (unsigned char)(red * 255.), (unsigned char)(green * 255.), (unsigned char)(blue * 255.)];
}


@end
