//
//  MGSMemoryManagement.h
//  KosmicTask
//
//  Created by Jonathan on 07/12/2009.
//  Copyright 2009 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MGSMemoryManagement : NSObject {

}

+ (void)collectExhaustivelyAfterDelay:(NSTimeInterval)delay;

@end
