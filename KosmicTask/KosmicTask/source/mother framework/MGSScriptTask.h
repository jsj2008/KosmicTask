//
//  MGSScriptTask.h
//  Mother
//
//  Created by Jonathan Mitchell on 29/12/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSTask.h"

@class MGSServerNetRequest;


@interface MGSScriptTask : MGSTask {
	MGSServerNetRequest *_netRequest;
    MGSServerNetRequest *_logRequest;
}
- (MGSScriptTask *)initWithNetRequest:(MGSServerNetRequest *)netRequest;

@property MGSServerNetRequest *netRequest;
@property MGSServerNetRequest *logRequest;
@end
