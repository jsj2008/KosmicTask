//
//  NSBezierPath_Mugginsoft.m
//  Mother
//
//  Created by Jonathan on 14/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "NSBezierPath_Mugginsoft.h"


@implementation NSBezierPath (MugginsSoft)
// see NSBezierPath +strokeLineFromPoint:inner toPoint:outer
+ (NSBezierPath *)bezierPathLineFrom:(NSPoint)start to:(NSPoint)end
{
	NSBezierPath *path = [self bezierPath];
	[path moveToPoint:start];
	[path lineToPoint:end];
	return path;
}

/* bezierPathWithRoundRectInRect
 * Create a rectangluar bezier path with rounded corners. Radius is the radius of the corners.
 */
+(NSBezierPath *)bezierPathWithRoundRectInRect:(NSRect)aRect radius:(float)radius
{
	NSBezierPath * path = [NSBezierPath bezierPath];
	radius = MIN(radius, 0.5f * MIN(NSWidth(aRect), NSHeight(aRect)));
	NSRect rect = NSInsetRect(aRect, radius, radius);
	[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(rect), NSMinY(rect)) radius:radius startAngle:180 endAngle:270];
	[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(rect), NSMinY(rect)) radius:radius startAngle:270 endAngle:360];
	[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(rect), NSMaxY(rect)) radius:radius startAngle:  0 endAngle: 90];
	[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(rect), NSMaxY(rect)) radius:radius startAngle: 90 endAngle:180];
	[path closePath];
	return path;
}

@end
