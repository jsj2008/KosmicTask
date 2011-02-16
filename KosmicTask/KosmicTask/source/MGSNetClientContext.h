//
//  MGSNetClientContext.h
//  KosmicTask
//
//  Created by Jonathan on 08/12/2009.
//  Copyright 2009 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSMotherModes.h"

@interface MGSNetClientContext : NSObject {
	NSWindow *_window;					// window associated with this context
	eMGSMotherRunMode _runMode;					// client run mode
	eMGSMotherRunMode _pendingRunMode;			// pending client run mode
}

@property eMGSMotherRunMode runMode;
@property eMGSMotherRunMode pendingRunMode;

- (id)initWithWindow:(NSWindow *)window;

@end
