//
//  NSObject+MGSDisposable.m
//  KosmicTask
//
//  Created by Mitchell Jonathan on 09/03/2012.
//  Copyright (c) 2012 Mugginsoft. All rights reserved.
//

#import "NSObject+MGSDisposable.h"
#import <objc/runtime.h>

static char mgsDisposableKey;

@implementation NSObject (MGSDisposable)

/*
 
 - mgsMakeDisposable
 
 */
- (void)mgsMakeDisposable
{
    // check if already disposable
    if ([self isMgsDisposable]) {
        return;
    }
    
    // assign an initial reference count of 1
    NSNumber *refCount = [NSNumber numberWithUnsignedInteger:1];
    [self mgsAssociateValue:refCount withKey:&mgsDisposableKey];
}

/*
 
 - isMgsDisposable
 
 */
- (BOOL)isMgsDisposable
{
    return ([self mgsDisposalCount] == NSUIntegerMax ? NO : YES);
}

/*
 
 - mgsDisposalCount
 
 */
- (NSUInteger)mgsDisposalCount
{
    NSNumber *refCount = [self mgsAssociatedValueForKey:&mgsDisposableKey];
    if (!refCount) {
        return NSUIntegerMax;
    }
    
    return [refCount unsignedIntegerValue];
}

/*
 
 - isMgsDisposed
 
 */
- (BOOL)isMgsDisposed
{
    NSUInteger refCount = [self mgsDisposalCount];
    return (refCount == 0 ? YES : NO);
}

/*
 
 - mgsRetainDisposable
 
 */
- (void)mgsRetainDisposable
{
    if (![self isMgsDisposable]) return;
    if ([self isMgsDisposed]) return;
    
    NSUInteger refCount = [self mgsDisposalCount];
    if (refCount == NSUIntegerMax) {
        return;
    }
    
    [self mgsAssociateValue:[NSNumber numberWithUnsignedInteger:++refCount] withKey:&mgsDisposableKey];
}

/*
 
 - mgsReleaseDisposable
 
 */
- (void)mgsReleaseDisposable
{
    if (![self isMgsDisposable]) return;
    if ([self isMgsDisposed]) return;
    
    NSUInteger refCount = [self mgsDisposalCount];
    if (refCount == NSUIntegerMax) {
        return;
    }

    // dispose prior to reference count update
    if (refCount == 1) {
        [self mgsDispose];
    }
    
    [self mgsAssociateValue:[NSNumber numberWithUnsignedInteger:--refCount] withKey:&mgsDisposableKey];
    
}

/*
 
 - mgsDispose
 
 */
- (void)mgsDispose
{
    // we must be disposable
    if (![self isMgsDisposable]) return;
    
    // log if already disposed
    if ([self isMgsDisposedWithLogIfTrue]) return;
}

/*
 
 - isMgsDisposedWithLogIfTrue
 
 */
- (BOOL)isMgsDisposedWithLogIfTrue
{
    if (![self isMgsDisposable]) return NO;
    
    BOOL disposed = [self isMgsDisposed];
    if (disposed) {
        NSLog(@"mgsDispose already called.");
    }
    
    return disposed;
}

/*
 
 - mgsAssociateValue
 
 */
- (void)mgsAssociateValue:(id)value withKey:(void *)key
{
	objc_setAssociatedObject(self, key, value, OBJC_ASSOCIATION_RETAIN);
}

/*
 
 - mgsWeaklyAssociateValue
 
 */
- (void)mgsWeaklyAssociateValue:(id)value withKey:(void *)key
{
	objc_setAssociatedObject(self, key, value, OBJC_ASSOCIATION_ASSIGN);
}

/*
 
 - mgsAssociatedValueForKey
 
 */
- (id)mgsAssociatedValueForKey:(void *)key
{
	return objc_getAssociatedObject(self, key);
}


@end
