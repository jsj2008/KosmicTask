//
//  NSColor_Mugginsoft.h
//  KosmicTask
//
//  Created by Jonathan on 07/04/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSColor (Mugginsoft) 
+ (NSColor *) mgs_colorWithHTMLAttributeValue:(NSString *) attribute;
+ (NSColor *) mgs_colorWithCSSAttributeValue:(NSString *) attribute;
- (NSString *) mgs_HTMLAttributeValue;
- (NSString *) mgs_CSSAttributeValue;
@end
