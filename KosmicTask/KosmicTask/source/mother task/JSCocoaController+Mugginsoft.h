//
//  JSCocoaController+Mugginsoft.h
//  KosmicTask
//
//  Created by Jonathan on 20/11/2012.
//
//

#import <JSCocoa/JSCocoa.h>

extern void QuietLog (NSString *format, ...) __attribute__((format(__NSString__, 1, 2)));

@interface JSCocoaController (Mugginsoft)

+ (void)qlog:(NSString *)value;
- (void)qlog:(NSString *)value;
@end
