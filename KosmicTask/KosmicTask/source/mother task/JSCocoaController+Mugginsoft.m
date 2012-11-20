
//
//  JSCocoaController+Mugginsoft.m
//  KosmicTask
//
//  Created by Jonathan on 20/11/2012.
//
//

#import "JSCocoaController+Mugginsoft.h"
#import <Foundation/Foundation.h>

/*
 
QuietLog
 
 */
void QuietLog (NSString *format, ...) {
    va_list argList;
    
    va_start (argList, format);
    NSString *message = [[NSString alloc] initWithFormat: format arguments: argList]; // autorelease if not ARC
    va_end (argList);
    
    fprintf (stderr, "%s\n", [message UTF8String]);
    
}

@implementation JSCocoaController (Mugginsoft)

/*
 
 + qlog
 
 */
+ (void)qlog:(NSString *)value
{
    QuietLog(@"%@", value);
}

/*
 
 - qlog
 
 */
- (void)qlog:(NSString *)value
{
    QuietLog(@"%@", value);
}
@end
