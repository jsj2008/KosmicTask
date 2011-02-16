//
//  MGSArrayController.h
//  Mother
//
//  Created by Jonathan on 10/07/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MGSArrayController : NSArrayController {
	BOOL _modelDataModified;
}

@property BOOL modelDataModified;

@end
