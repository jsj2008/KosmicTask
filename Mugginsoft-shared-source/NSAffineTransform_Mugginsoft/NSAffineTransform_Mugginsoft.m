//
//  NSAffineTransform_Mugginsoft.m
//  KosmicTask
//
//  Created by Jonathan on 05/12/2009.
//  Copyright 2009 mugginsoft.com. All rights reserved.
//

#import "NSAffineTransform_Mugginsoft.h"

@implementation NSAffineTransform (RectMapping)

- (NSAffineTransform*)mapFrom:(NSRect) src to: (NSRect) dst {
    NSAffineTransformStruct at;
    at.m11 = (dst.size.width/src.size.width);
    at.m12 = 0.0f;
    at.tX = dst.origin.x - at.m11*src.origin.x;
    at.m21 = 0.0f;
    at.m22 = (dst.size.height/src.size.height);
    at.tY = dst.origin.y - at.m22*src.origin.y;
    [self setTransformStruct: at];
    return self;
}

/* create a transform that proportionately scales bounds to a rectangle of height
 centered distance units above a particular point.   */
- (NSAffineTransform*)scaleBounds:(NSRect) bounds 
						 toHeight: (float) height centeredDistance:(float) distance abovePoint:(NSPoint) location {
    NSRect dst = bounds;
    float scale = (height / dst.size.height);
    dst.size.width *= scale;
    dst.size.height *= scale;
    dst.origin.x = location.x - dst.size.width/2.0f;
    dst.origin.y = location.y + distance;
    return [self mapFrom:bounds to:dst];
}

/* create a transform that proportionately scales bounds to a rectangle of height
 centered distance units above the origin.   */
- (NSAffineTransform*)scaleBounds:(NSRect) bounds toHeight: (float) height
			  centeredAboveOrigin:(float) distance {
    return [self scaleBounds: bounds toHeight: height centeredDistance:
            distance abovePoint: NSMakePoint(0,0)];
}


/* initialize the NSAffineTransform so it will flip the contents of bounds
 vertically. */
- (NSAffineTransform*)flipVertical:(NSRect) bounds {
    NSAffineTransformStruct at;
    at.m11 = 1.0f;
    at.m12 = 0.0f;
    at.tX = 0;
    at.m21 = 0.0f;
    at.m22 = -1.0f;
    at.tY = bounds.size.height;
    [self setTransformStruct: at];
    return self;
}


@end
