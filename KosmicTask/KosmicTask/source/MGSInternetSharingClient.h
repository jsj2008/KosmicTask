//
//  MGSInternetSharingClient.h
//  Mother
//
//  Created by Jonathan on 08/09/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSInternetSharing.h"

@interface MGSInternetSharingClient : MGSInternetSharing {
	BOOL _portMapperIsWorking;
    BOOL _portCheckerIsWorking;
	NSString *_startStopButtonText;
	NSImage *_appIconImage;
	NSImage *_appActiveSharingIconImage;
    NSString *_portStatusText;
    NSString *_routerStatusText;
    NSInvocation *_requestInvocation;
    BOOL _processingResponse;
}

@property (readonly) NSString *startStopButtonText;
@property (readonly) NSString *portStatusText;
@property (readonly) NSString *routerStatusText;


- (void)requestPortCheck;
- (void)requestMappingRefresh;
+ (id)sharedInstance;
@end
