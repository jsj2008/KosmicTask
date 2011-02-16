//
//  MGSServerTaskConfiguration.h
//  Mother
//
//  Created by Jonathan on 10/09/2009.
//  Copyright 2009 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MGSServerTaskConfiguration : NSObject {
	NSOperationQueue *_operationQueue;
}

- (void)validateMetadata;
- (void)importBundleMetadata;
- (void)validateApplicationTasks;
- (void)queueOperation:(NSInvocationOperation *)theOp;
- (BOOL)copyBundleDocumentsToPath:(NSString *)folder;
- (BOOL)removeAllBundledTasksAtPath:(NSString *)folder;
@end
