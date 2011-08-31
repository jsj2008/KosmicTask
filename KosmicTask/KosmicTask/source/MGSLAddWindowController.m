//
//  MGSLAddWindowController.m
//  Mother
//
//  Created by Jonathan on 02/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSLAddWindowController.h"
#import "MGSLM.h"
#import "MGSL.h"
#import "MGSUser.h"

@implementation MGSLAddWindowController

@synthesize path = _path;
@synthesize licenceType = _licenceType;

/*
 
 init with path
 
 */
- (id)initWithPath:(NSString *)path
{
	if ([super initWithWindowNibName:@"AddLicenceWindow"]) {
		_path = path;
		_licenceType = MGSLTypeIndividual;
	}
	return self;
}

/* 
 
 add licence
 
 */
- (IBAction)addLicence:(id)sender
{
	#pragma unused(sender)
	
	[NSApp endSheet:[self window] returnCode:1];
}

/*
 
 cancel
 
 */
- (IBAction)cancel:(id)sender
{
	#pragma unused(sender)
	
	[NSApp endSheet:[self window] returnCode:0];
}

/*
 
 window did load
 
 */
- (void)windowDidLoad
{
	// bind detail table view controller o dictionary controller
	_licenceDictionaryController = [[NSDictionaryController alloc] init];
	[_licenceDictionaryController setContent:[[MGSLM sharedController] dictionaryOfItemAtPath:_path]];
	
	[[_detailTableView tableColumnWithIdentifier:@"name"] bind:@"value" toObject:_licenceDictionaryController withKeyPath:@"arrangedObjects.key" options:nil];
	[[_detailTableView tableColumnWithIdentifier:@"value"] bind:@"value" toObject:_licenceDictionaryController withKeyPath:@"arrangedObjects.value" options:nil];

	// only admin users may select licensing options.
    // on lion non admin users can no longer write to /library/application support
    // so better to disable support for it
	BOOL enableLicenceOptions;
	if ([[MGSUser currentUser] isMemberOfAdminGroup] && NO) {
		[_licenceTypePopup setMenu:adminLicenceTypeMenu];
		enableLicenceOptions = YES;
		self.licenceType = MGSLTypeComputer;
	} else {
		[_licenceTypePopup setMenu:userLicenceTypeMenu];
		enableLicenceOptions = NO;
		self.licenceType = MGSLTypeIndividual;
	}
	
	// enable option controls
	// doesn't seem to work!
	[_licenceTypePopup setEnabled:enableLicenceOptions];	// swap in different menus to restrict options instead
	
	// bind licence type popup index
	[_licenceTypePopup bind:NSSelectedIndexBinding toObject:self withKeyPath:@"licenceType" options:nil];
}


/*
 
 option dictionary
 
 */
- (NSDictionary *)optionDictionary
{
	NSMutableDictionary *dictionary = [MGSLM defaultOptionDictionary];	
	NSNumber *licenceType = [NSNumber numberWithInteger:self.licenceType];
	[dictionary setObject:licenceType forKey:MGSTypeLicenceKey];
	return [NSDictionary dictionaryWithDictionary:dictionary];
}
@end
