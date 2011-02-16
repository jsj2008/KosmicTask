//
//  NSNetServices_Errors.h
//  Mother
//
//  Created by Jonathan on 19/11/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSNetService (Errors) 
+ (NSString *)errorDictString:(NSDictionary *)errors;
@end
