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
	BOOL _processingResponse;
	NSString *_startStopButtonText;
	NSImage *_appIconImage;
	NSImage *_appActiveSharingIconImage;
    NSString *_portStatusText;
    NSInvocation *_requestInvocation;
}

@property (readonly) NSString *startStopButtonText;
@property (readonly) NSString *portStatusText;

- (void)requestStatusUpdate;
+ (id)sharedInstance;
@end
