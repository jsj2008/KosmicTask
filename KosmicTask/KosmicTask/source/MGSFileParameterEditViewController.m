//
//  MGSFileParameterEditViewController.m
//  Mother
//
//  Created by Jonathan on 06/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSFileParameterPlugin.h"
#import "MGSFileParameterEditViewController.h"


@implementation MGSFileParameterEditViewController

@synthesize useFileExtensions = _useFileExtensions;
@synthesize fileExtensions = _fileExtensions;

/*
 
 init  
 
 */
- (id)init
{
	if ([super initWithNibName:@"FileParameterEditView"]) {
		
	}
	return self;
}



/*
 
 awake from nib
 
 */
- (void)awakeFromNib
{
	[fileExtensionsTextField bind:NSValueBinding toObject:self withKeyPath:@"fileExtensions" options:[NSDictionary dictionaryWithObjectsAndKeys: @"ext1 ext2 ext3...", NSNullPlaceholderBindingOption, nil]];
	[useRequiredFileExtensionCheckbox bind:NSValueBinding toObject:self withKeyPath:@"useFileExtensions" options:nil];
	
	// this will send viewDidLoad to delegate
	[super awakeFromNib];
}

/*
 
 - setFileExtensions:
 
 */
- (void)setFileExtensions:(NSString *)aString
{
	if (!aString) aString = @"";
	_fileExtensions = aString;
}
/*
 
 update plist
 
 */
- (void)updatePlist
{
	[self.plist setObject:[NSNumber numberWithBool:self.useFileExtensions] forKey:MGSKeyUseFileExtensions];
	[self.plist setObject:self.fileExtensions forKey:MGSKeyFileExtensions];
}

/*
 
 initialise from plist
 
 */
- (void)initialiseFromPlist
{
	self.useFileExtensions = [[self.plist objectForKey:MGSKeyUseFileExtensions withDefault:[NSNumber numberWithBool:NSOffState]] boolValue];
	self.fileExtensions = [self.plist objectForKey:MGSKeyFileExtensions withDefault:@""];
}
@end
