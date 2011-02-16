//
//  MGSBonjour.m
//  Mother
//
//  Created by Jonathan on 31/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSBonjour.h"
#import "MGSSystem.h"

NSString *MGSBonjourDomain = @"";
NSString *MGSBonjourServiceType = @"_msss._tcp.";

NSString *MGSTxtRecordKeyUser = @"user";
NSString *MGSTxtRecordKeySSL = @"ssl";

@implementation MGSBonjour 

+ (NSString *)serviceName
{
	return [[MGSSystem sharedInstance] localHostName];
}

@end
