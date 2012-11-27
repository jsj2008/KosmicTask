//
//  MGSActionInfoViewController.m
//  Mother
//
//  Created by Jonathan on 30/07/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSActionInfoViewController.h"
#import "MGSScript.h"
#import "MGSTaskSpecifier.h"
#import "NSTextField_Mugginsoft.h"

@implementation MGSActionInfoViewController


@synthesize actionSpecifier = _actionSpecifier;

/*
 
 init
 
 */
-(id)init 
{
	if ([super initWithNibName:@"ActionInfoView" bundle:nil]) {
	}
	return self;
}

/*
 
 awake from nib
 
 */

- (void)awakeFromNib
{
	[[_actionUUIDTextField cell] setLineBreakMode:NSLineBreakByTruncatingTail];
}

/*
 
 set action
 
 */
- (void)setActionSpecifier:(MGSTaskSpecifier *)action
{
	_actionSpecifier = action;
	MGSScript *script = [action script];
	
	NSString *versionString = [NSString stringWithFormat:@"%ld.%ld.%ld", (long)[script versionMajor], (long)[script versionMinor], (long)[script versionRevision]];
	[_authorName setStringValueOrEmptyOnNil:[script author]];
	[_scriptType setStringValueOrEmptyOnNil:[script scriptType]];
	[_authorNote setStringValueOrEmptyOnNil:[script authorNote]];
	[_dateCreated setStringValueOrEmptyOnNil:[[script created] descriptionWithLocale: [NSLocale currentLocale]]];
	[_dateModified setStringValueOrEmptyOnNil:[[script modified] descriptionWithLocale: [NSLocale currentLocale]]];
	[_version setStringValueOrEmptyOnNil:versionString];
	[_actionUUIDTextField setStringValue: [script UUID]];	
}

@end
