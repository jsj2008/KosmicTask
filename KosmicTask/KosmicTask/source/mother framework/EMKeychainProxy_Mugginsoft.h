//
//  EMKeychainProxy_Mugginsoft.h
//  Mother
//
//  Created by Jonathan on 22/04/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface EMKeychainProxy (Mugginsoft)
- (EMGenericKeychainItem *)genericKeychainItemForService:(NSString *)serviceNameString;
@end
