//
//  NSBezierPath_Mugginsoft.h
//  Mother
//
//  Created by Jonathan on 14/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSBezierPath (MugginsSoft)
+ (NSBezierPath *)bezierPathLineFrom:(NSPoint)start to:(NSPoint)end;
+(NSBezierPath *)bezierPathWithRoundRectInRect:(NSRect)aRect radius:(float)radius;
@end
