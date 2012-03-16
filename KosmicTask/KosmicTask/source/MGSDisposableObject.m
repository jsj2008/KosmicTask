//
//  MGSDisposableObject.m
//  KosmicTask
//
//  Created by Mitchell Jonathan on 09/03/2012.
//  Copyright (c) 2012 Mugginsoft. All rights reserved.
//

#import "MGSDisposableObject.h"

// class extension
@interface MGSDisposableObject()
@property (readwrite) NSUInteger disposalCount;
@property (readwrite) BOOL disposed;
@end

@implementation MGSDisposableObject

@synthesize disposed, disposalCount;

- (id)init
{
    self = [super init];
    if (self) {
        disposed = NO;
        self.disposalCount = 1;
    }
    
    return self; 
}

#pragma mark -
#pragma mark accessors

/*
 
 - setDisposalCount
 
 */
- (void)setDisposalCount:(NSUInteger)value
{
    disposalCount = value;
    
#ifdef MGS_LOG_ME
    NSLog(@"%@ -disposalCount: %u", self, disposalCount);
#endif
    
    // if disposalCount is 0 we dispose of our resources
    if (self.disposalCount == 0) {
        
#ifdef MGS_LOG_ME
        NSLog(@"%@ calling -dispose", self);
#endif        
        [self dispose];
    }
    
}

#pragma mark -
#pragma mark resource management
/*
 
 - retainDisposable
 
 */
- (void)retainDisposable
{
    if ([self isDisposedWithLogIfTrue]) {
        return;
    }
    self.disposalCount++;
}
/*
 
 - releaseDisposable
 
 */
- (void)releaseDisposable
{
    if ([self isDisposedWithLogIfTrue]) {
        return;
    }

    if (self.disposalCount <= 0) {
        NSLog(@"Reference count is already 0.");
        return;
    }
    
    --self.disposalCount;
}
/*
 
 - isDisposedWithLogIfTrue
 
 */
- (BOOL)isDisposedWithLogIfTrue
{
    if (self.disposed) {
		NSLog(@"%@. Dispose already called.", self);
	}
    
    return self.disposed;
}
/*
 
 - dispose
 
 -finalize cannot safely access its ivars and pass them to other objects 
 as the objects and its ivars may get collected in the same collection cycle.
 if the already finalized ivar then gets referenced by another object during
 the finalization of self we get a resurrection error.
 
 
 */
- (void)dispose
{
#ifdef MGS_LOG_ME
    NSLog(@"%@ base class received -dispose", self);
#endif 
    
    if ([self isDisposedWithLogIfTrue]) {
        return;
    }
    if (self.disposalCount != 0) {
        NSLog(@"Cannot dispose. Disposal count is not zero.");
        return;
    }
	self.disposed = YES;
}

#pragma mark -
#pragma mark memory management
/*
 
 - finalize
 
 only access non objects during finalize
 
 */
- (void)finalize
{
    if (!self.disposed) {
        NSLog(@"%@. This object may be leaking disposable resources. -dispose has not been called prior to -finalize.", self);
    }
    
    [super finalize];
}
@end
