//
//  MGSScriptController.h
//  Mother
//
//  Created by Jonathan Mitchell on 29/12/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSScriptTask.h"

@class MGSNetRequest;

@interface MGSClientScriptHandler : NSObject <MGSTaskDelegate> {
	NSMutableDictionary *_scriptsDictionary;
	NSMutableArray *_scriptTasks;
}

- (NSString *) path;
- (NSString *) userPath;
- (BOOL)loadDictionary;
- (NSDictionary *)dictionary;
- (NSData *)dictionaryAsData;
- (BOOL)parseNetRequest:(MGSNetRequest *)netRequest;
@end
