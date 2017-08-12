//
//  MGSKosmicCardTabStyle.m
//  KosmicTask
//
//  Created by Jonathan on 18/02/2013.
//
//

#import "MGSKosmicCardTabStyle.h"
#import "PSMTabBarControl/PSMTabBarCell.h"
#import "PSMTabBarControl/PSMTabBarControl.h"

@implementation MGSKosmicCardTabStyle

+ (NSString *)name {
    return @"KosmicCard";
}

- (NSString *)name {
	return [[self class] name];
}

- (CGFloat)topMarginForTabBarControl:(PSMTabBarControl *)tabBarControl {
#pragma unused(tabBarControl)
    
	return 10.0f;
}

#pragma mark -
#pragma mark Drawing

- (void)drawBezelOfTabBarControl:(PSMTabBarControl *)tabBarControl inRect:(NSRect)rect
{
#pragma unused(tabBarControl)
#pragma unused(rect)
    
    return;
}

- (void)drawBezelOfTabCell:(PSMTabBarCell *)cell withFrame:(NSRect)frame inTabBarControl:(PSMTabBarControl *)tabBarControl
{
#pragma unused(frame)
    
    NSRect cellFrame = [cell frame];
	
    NSBezierPath *bezier = [NSBezierPath bezierPath];
    NSColor * lineColor = [NSColor grayColor];
    
    NSRect aRect = NSMakeRect(cellFrame.origin.x+.5, cellFrame.origin.y+0.5, cellFrame.size.width-1.0, cellFrame.size.height-1.0);
    
    // frame
    CGFloat radius = MIN(6.0, 0.5f * MIN(NSWidth(aRect), NSHeight(aRect)))-0.5;
    
    [bezier moveToPoint: NSMakePoint(NSMinX(aRect),NSMaxY(aRect)+1.0)];
    [bezier appendBezierPathWithArcFromPoint:NSMakePoint(NSMinX(aRect),NSMinY(aRect)) toPoint:NSMakePoint(NSMidX(aRect),NSMinY(aRect)) radius:radius];
    [bezier appendBezierPathWithArcFromPoint:NSMakePoint(NSMaxX(aRect),NSMinY(aRect)) toPoint:NSMakePoint(NSMaxX(aRect),NSMaxY(aRect)) radius:radius];
    [bezier lineToPoint: NSMakePoint(NSMaxX(aRect),NSMaxY(aRect)+1.0)];
    
    NSGradient *gradient = nil;
    
    if([tabBarControl isWindowActive]) {
        if ([cell state] == NSOnState) {
            //gradient = [[NSGradient alloc] initWithStartingColor:[NSColor whiteColor] endingColor:[NSColor colorWithDeviceWhite:0.929 alpha:1.000]];
        } else if ([cell isHighlighted]) {
            
            gradient = [[NSGradient alloc]
                        initWithStartingColor: [NSColor colorWithCalibratedWhite:0.80 alpha:1.0]
                        endingColor:[NSColor colorWithCalibratedWhite:0.80 alpha:1.0]];
        } else {
            
            gradient = [[NSGradient alloc]
                        initWithStartingColor:[NSColor colorWithCalibratedWhite:0.835 alpha:1.0]
                        endingColor:[NSColor colorWithCalibratedWhite:0.843 alpha:1.0]];
        }
        
        if (gradient != nil) {
            [gradient drawInBezierPath:bezier angle:90.0f];
            gradient = nil;
        } else {
            [[NSColor textBackgroundColor] set];
            [bezier fill];
        }
    } else {
        if ([cell state] == NSOnState) {
            [[NSColor textBackgroundColor] set];
            [bezier fill];
        } else {
            [[NSColor windowBackgroundColor] set];
            NSRectFill(aRect);
        }
    }
    
    [lineColor set];
    [bezier stroke];
}

@end
