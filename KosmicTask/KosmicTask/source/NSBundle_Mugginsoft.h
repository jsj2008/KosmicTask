//
//  NSBundle_Mugginsoft.h
//  Mother
//
//  Created by Jonathan on 28/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSBundle (Mugginsoft)

+ (id)mainBundleInfoObjectForKey:(NSString*)key;
- (NSString *)pathForCustomAuxiliaryExecutable:(NSString *)execName;

@end
