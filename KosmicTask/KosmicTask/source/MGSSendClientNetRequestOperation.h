//
//  MGSSendClientNetRequestOperation.h
//  KosmicTask
//
//  Created by Jonathan on 27/10/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MGSSendClientNetRequestOperation : NSOperation {
    BOOL        executing;
    BOOL        finished;
}

@end
