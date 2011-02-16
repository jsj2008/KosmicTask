//
//  PreferenceControllers.h
//  mother
//
//  Created by Jonathan Mitchell on 07/10/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSDebugController.h"

@interface MGSPreferencesController : NSWindowController {
	MGSDebugController *debugController;
}

- (IBAction) showDebugPanel:(id)sender;

@end
