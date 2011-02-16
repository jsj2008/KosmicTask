//
//  DebugController.h
//  mother
//
//  Created by Jonathan Mitchell on 06/10/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MGSDebugController : NSWindowController {
	IBOutlet NSTextField *coreDumpProcess;
}

- (IBAction) raiseException:(id)sender;
- (IBAction) assertFail:(id)sender;
- (IBAction) collect:(id)sender;
@end
