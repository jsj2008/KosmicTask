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
	MGSScript * _script;
	MGSNetRequest * _netRequest;
	MGSError * _error;
	BOOL _boolValue;
}

@property (strong) MGSScript *script;
@property (strong) MGSNetRequest *netRequest;
@property (strong) MGSError *error;
@property BOOL boolValue;
@end
