//
//  MGSBonjour.h
//  Mother
//
//  Created by Jonathan on 31/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *MGSBonjourDomain;
extern NSString *MGSBonjourServiceType;

// TXT record keys
extern NSString *MGSTxtRecordKeyUser;
extern NSString *MGSTxtRecordKeySSL;


#define MGS_TXT_RECORD_YES @"YES"
#define MGS_TXT_RECORD_NO @"NO"

@interface MGSBonjour : NSObject {
	
}

+ (NSString *)serviceName;

@end
