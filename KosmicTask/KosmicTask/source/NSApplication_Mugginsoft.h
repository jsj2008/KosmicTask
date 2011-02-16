//
//  NSApplication_Mugginsoft.h
//  Mother
//
//  Created by Jonathan on 29/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSApplication (Mugginsoft)

+ (void)getSystemVersionMajor:(unsigned *)major
                        minor:(unsigned *)minor
                       bugFix:(unsigned *)bugFix;

@end
