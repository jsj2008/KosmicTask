//
//  MGSSystem.h
//  Mother
//
//  Created by Jonathan on 29/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MGSSystem : NSObject {

}
+ (id)sharedInstance;
- (BOOL)OSVersionIsSupported;
- (NSString *)minOSVersionSupported;
- (NSString *)machineSerialNumber;
- (NSString *)localHostName;
@end
