//
//  MGSActionInfoViewController.h
//  Mother
//
//  Created by Jonathan on 30/07/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MGSTaskSpecifier;

@interface MGSActionInfoViewController : NSViewController {
	MGSTaskSpecifier *_actionSpecifier;
	
	IBOutlet NSTextField *_authorName;
	IBOutlet NSTextField *_authorNote;
	IBOutlet NSTextField *_dateCreated;
	IBOutlet NSTextField *_dateModified;
	IBOutlet NSTextField *_version;
	IBOutlet NSTextField *_actionUUIDTextField;
}


@property MGSTaskSpecifier *actionSpecifier;

@end
