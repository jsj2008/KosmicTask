//
//  MGSServerRequestThreadHelper.h
//  Mother
//
//  Created by Jonathan on 15/09/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MGSScript;
@class MGSNetRequest;
@class MGSError;

@interface MGSServerRequestThreadHelper : NSObject {
	MGSScript *_script;
	MGSNetRequest *_netRequest;
	MGSError *_error;
	BOOL _boolValue;
}

@property (assign) MGSScript *script;
@property (assign) MGSNetRequest *netRequest;
@property (assign) MGSError *error;
@property BOOL boolValue;
@end
