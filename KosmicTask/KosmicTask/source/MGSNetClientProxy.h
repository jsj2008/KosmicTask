//
//  MGSNetClientProxy.h
//  Mother
//
//  Created by Jonathan on 04/10/2009.
//  Copyright 2009 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "MGSNetClient.h"

@interface MGSNetClientProxy : NSObject {
	NSString *_serviceName;				// Bonjour service name - full host name
	NSString *_serviceShortName;		// Bonjour service name - host name minus .local domain
	NSImage *_hostIcon;					// 16x16 image representing host type and status
	MGSHostStatus _hostStatus;			// host status
}

@property (copy) NSString *serviceShortName;
@property (copy) NSString *serviceName;
@property (assign) NSImage *hostIcon;
@property MGSHostStatus hostStatus;

@end
