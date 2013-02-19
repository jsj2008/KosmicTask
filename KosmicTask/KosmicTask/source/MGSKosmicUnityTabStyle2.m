//
//  MGSKosmicUnityTabStyle2.m
//  KosmicTask
//
//  Created by Jonathan on 19/02/2013.
//
//

#import "MGSKosmicUnityTabStyle2.h"

#import "PSMTabBarControl/PSMTabBarCell.h"
#import "PSMTabBarControl/PSMTabBarControl.h"

@implementation MGSKosmicUnityTabStyle2

+ (NSString *)name {
    return @"KosmicUnity2";
}

- (NSString *)name {
	return [[self class] name];
}

- (CGFloat)leftMarginForTabBarControl:(PSMTabBarControl *)tabBarControl {
#pragma unused(tabBarControl)
	return 5.0f;
}

#pragma mark -
#pragma mark Drawing

-(void)drawBezelOfTabCell:(PSMTabBarCell *)cell withFrame:(NSRect)frame inTabBarControl:(PSMTabBarControl *)tabBarControl
{
	NSBezierPath *bezier = [NSBezierPath bezierPath];
	NSColor *lineColor = [NSColor colorWithCalibratedWhite:0.500 alpha:1.0];
    
    NSRect aRect = NSMakeRect(frame.origin.x + 0.5, frame.origin.y - 0.5, frame.size.width, frame.size.height);
    
    if ([cell isHighlighted] && [cell state] == NSOffState)
    {
        aRect.origin.y += 1.5;
        aRect.size.height -= 1.5;
    }
    
    CGFloat radius = MIN(6.0, 0.5f * MIN(NSWidth(aRect), NSHeight(aRect)));
    NSRect rect = NSInsetRect(aRect, radius, radius);
    
    NSPoint cornerPoint = NSMakePoint(NSMaxX(aRect), NSMinY(aRect));
    [bezier appendBezierPathWithPoints:&cornerPoint count:1];
    
    [bezier appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(rect), NSMaxY(rect)) radius:radius startAngle:0.0 endAngle:90.0];
    
    [bezier appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(rect), NSMaxY(rect)) radius:radius startAngle:90.0 endAngle:180.0];
    
    cornerPoint = NSMakePoint(NSMinX(aRect), NSMinY(aRect));
    [bezier appendBezierPathWithPoints:&cornerPoint count:1];
    
    if ([tabBarControl isWindowActive]) {
        if ([cell state] == NSOnState) {
            NSColor *startColor = [NSColor windowBackgroundColor];
            [startColor set];
            [bezier fill];
        } else if ([cell isHighlighted]) {
            NSColor *startColor = [NSColor colorWithDeviceWhite:0.650 alpha:0.5];
            NSColor *endColor = [NSColor colorWithDeviceWhite:0.650 alpha:0.5];
            NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:startColor endingColor:endColor];
            [gradient drawInBezierPath:bezier angle:90.0];
            [gradient release];
        }
        
    } else {
        if ([cell state] == NSOnState) {
            NSColor *startColor = [NSColor windowBackgroundColor];
            [startColor set];
            [bezier fill];
        }
    }
    
    [lineColor set];
    [bezier stroke];
}

- (void)drawBezelOfTabBarControl:(PSMTabBarControl *)tabBarControl inRect:(NSRect)rect {
	//Draw for our whole bounds; it'll be automatically clipped to fit the appropriate drawing area
	rect = [tabBarControl bounds];
    
	NSRect gradientRect = rect;
	gradientRect.size.height -= 0.0;
    

    if (YES) {
        NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceWhite:0.85 alpha:1.0] endingColor:[NSColor colorWithDeviceWhite:0.75 alpha:1.0]];
        [gradient drawInRect:gradientRect angle:90.0];
        [gradient release];
    }
    
    
	[[NSColor colorWithDeviceWhite:0.500 alpha:1.0] set];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(rect.origin.x, NSMinY(rect) + 0.5)
                              toPoint:NSMakePoint(NSMaxX(rect), NSMinY(rect) + 0.5)];
    
	[NSBezierPath strokeLineFromPoint:NSMakePoint(rect.origin.x, NSMaxY(rect) - 0.5)
                              toPoint:NSMakePoint(NSMaxX(rect), NSMaxY(rect) - 0.5)];
}

@end
