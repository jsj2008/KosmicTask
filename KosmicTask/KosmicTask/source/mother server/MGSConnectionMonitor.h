//
//  MGSConnectionMonitor.h
//  Mother
//
//  Created by Jonathan on 16/11/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MGSConnectionMonitor : NSObject {

}

@end

@interface MGSConnectionMonitor (NSNetServiceDelegate) 
@end

@interface MGSConnectionMonitor (NSConnectionDelegate) 
@end

@interface MGSConnectionMonitor (NSConnectionNotification)
@end
