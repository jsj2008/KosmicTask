//
//  NSImage+Mugginsoft.m
//  KosmicTask
//
//  Created by Jonathan on 21/11/2012.
//
//

#import "NSImage+Mugginsoft.h"

@implementation NSImage (Mugginsoft)

/*
 
 - imageRotatedByDegrees:
 
 http://www.cocoabuilder.com/archive/cocoa/231334-rotate-nsimage-to-get-new-nsimage-without-drawing.html
 
 */
- (NSImage *)imageRotatedByDegrees:(CGFloat)degrees
{
    // calculate the bounds for the rotated image
    NSRect imageBounds = {NSZeroPoint, [self size]};
    NSBezierPath* boundsPath = [NSBezierPath
                                bezierPathWithRect:imageBounds];
    NSAffineTransform* transform = [NSAffineTransform transform];
    
    [transform rotateByDegrees:degrees];
    [boundsPath transformUsingAffineTransform:transform];
    
    NSRect rotatedBounds = {NSZeroPoint, [boundsPath bounds].size};
    NSImage* rotatedImage = [[NSImage alloc]
                              initWithSize:rotatedBounds.size];
    
    // center the image within the rotated bounds
    imageBounds.origin.x = NSMidX(rotatedBounds) - (NSWidth
                                                    (imageBounds) / 2);
    imageBounds.origin.y = NSMidY(rotatedBounds) - (NSHeight
                                                    (imageBounds) / 2);
    
    // set up the rotation transform
    transform = [NSAffineTransform transform];
    [transform translateXBy:+(NSWidth(rotatedBounds) / 2) yBy:+
     (NSHeight(rotatedBounds) / 2)];
    [transform rotateByDegrees:degrees];
    [transform translateXBy:-(NSWidth(rotatedBounds) / 2) yBy:-
     (NSHeight(rotatedBounds) / 2)];
    
    // draw the original image, rotated, into the new image
    [rotatedImage lockFocus];
    [transform concat];
    [self drawInRect:imageBounds fromRect:NSZeroRect
           operation:NSCompositeCopy fraction:1.0] ;
    [rotatedImage unlockFocus];
    
    return rotatedImage;
}

@end
