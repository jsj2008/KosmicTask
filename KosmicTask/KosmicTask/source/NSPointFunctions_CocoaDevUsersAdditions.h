/*
 *  NSPointFunctions_CocoaDevUsersAdditions.h
 *  Mother
 *
 *  Created by Jonathan on 21/07/2008.
 *  Copyright 2008 Mugginsoft. All rights reserved.
 *
 */
//NSPointFunctions_CocoaDevUsersAdditions.h

#import <Cocoa/Cocoa.h>
#import <math.h>
#import <float.h> /* Standard C lib that contains some constants, look at http://www.acm.uiuc.edu/webmonkeys/book/c_guide/2.4.html -- JP */

const NSPoint NSFarAwayPoint = {FLT_MAX, FLT_MAX}; // FLT_MAX = 1E+27.  -- JP

static inline NSPoint CDUAddPoints(NSPoint firstPoint, NSPoint secondPoint)
{
	return NSMakePoint(firstPoint.x+secondPoint.x, firstPoint.y+secondPoint.y);
}

static inline NSPoint CDUSubtractPoints(NSPoint firstPoint, NSPoint secondPoint)
{
	return NSMakePoint(firstPoint.x-secondPoint.x, firstPoint.y-secondPoint.y);
}

static inline NSPoint CDUOffsetPoint(NSPoint point, float amountX, float amountY)
{
    return CDUAddPoints(point, NSMakePoint(amountX, amountY));
}

static inline NSPoint CDUReflectedPointAboutXAxis(NSPoint point)
{
    return NSMakePoint(-point.x, point.y);
}

static inline NSPoint CDUReflectedPointAboutYAxis(NSPoint point)
{
    return NSMakePoint(point.x, -point.y);
}

static inline NSPoint CDUReflectedPointAboutOrigin(NSPoint point)
{
    return NSMakePoint(-point.x, -point.y);
}

static inline NSPoint CDUTransformedPoint(NSPoint point,NSAffineTransform *transform)
{
	return [transform transformPoint:point];
}

static inline NSPoint CDUCartesianToPolar(NSPoint cartesianPoint)
{
    return NSMakePoint(sqrtf(cartesianPoint.x*cartesianPoint.x+cartesianPoint.y*cartesianPoint.y), atan2f(cartesianPoint.y,cartesianPoint.x));
}

static inline NSPoint CDUPolarToCartesian(NSPoint polarPoint)
{
    return NSMakePoint(polarPoint.x*cosf(polarPoint.y), polarPoint.x*sinf(polarPoint.y));
}

static inline NSPoint CDUMidPoint(NSPoint pt1, NSPoint pt2)
{
    return NSMakePoint((pt1.x+pt2.x)/2, (pt1.y+pt2.y)/2);
}
