//
//  MGSScriptTask.h
//  Mother
//
//  Created by Jonathan Mitchell on 29/12/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSTask.h"

@class MGSNetRequest;


@interface MGSScriptTask : MGSTask {
	MGSNetRequest *_netRequest;
    MGSNetRequest *_logRequest;
}
- (MGSScriptTask *)initWithNetRequest:(MGSNetRequest *)netRequest;

@property MGSNetRequest *netRequest;
@property MGSNetRequest *logRequest;
@end
