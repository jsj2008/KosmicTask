//
//  MGSDisposableObject.h
//  KosmicTask
//
//  Created by Mitchell Jonathan on 09/03/2012.
//  Copyright (c) 2012 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MGSDisposableObject : NSObject {
@private
    BOOL disposed;
    NSUInteger disposalCount;
}

@property (readonly) NSUInteger disposalCount;
@property (readonly, getter=isDisposed) BOOL disposed;

- (void)retainDisposable;
- (void)releaseDisposable;
- (void)dispose;
- (BOOL)isDisposedWithLogIfTrue;

@end

