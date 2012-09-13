//
//  NSMutableAttributedString+Mugginsoft.m
//  KosmicTask
//
//  Created by Jonathan on 13/09/2012.
//
//

#import "NSMutableAttributedString+Mugginsoft.h"

@implementation NSMutableAttributedString (Mugginsoft)

- (void)changeFont:(NSFont *)plainFont
{
    NSFont *boldFont = [[NSFontManager sharedFontManager] convertFont:plainFont toHaveTrait:NSBoldFontMask];
    [self enumerateAttribute:NSFontAttributeName
                     inRange:NSMakeRange(0, [self length])
                     options:0
                  usingBlock:^(id value,
                               NSRange range,
                               BOOL * stop)
     {
#pragma unused(stop)
#pragma unused(value)
         
         NSFont *newFont = plainFont;
         NSFont *font = value;
         if ([[NSFontManager sharedFontManager] traitsOfFont:font] & NSBoldFontMask) {
             newFont = boldFont;
         }
         [self removeAttribute:NSFontAttributeName range:range];
         [self addAttribute:NSFontAttributeName
                      value:newFont
                      range:range];
     }
     ];
}

@end
