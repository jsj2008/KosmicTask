//
//  MGSSecurity.h
//  Mother
//
//  Created by Jonathan on 27/03/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SecurityInterface/SFCertificatePanel.h>

@interface MGSSecurity : NSObject {

}

+ (void)showCertificate;
+ (BOOL)useDefaultIdentity;
+ (void)setUseDefaultIdentity:(BOOL)aBool;
+ (CFArrayRef)sslCertificatesArray;
+ (void)setIdentityOptions:(NSDictionary *)options;
@end
