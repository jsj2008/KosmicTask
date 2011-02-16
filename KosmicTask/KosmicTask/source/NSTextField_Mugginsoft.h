//
//  NSTextField_Mugginsoft.h
//  Mother
//
//  Created by Jonathan on 18/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSTextField (Mugginsoft)


- (float) verticalHeightToFit;
- (void)setStringValueOrEmptyOnNil:(NSString *)aString;
@end
