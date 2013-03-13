//
//  MGSListParameterInputViewController.m
//  Mother
//
//  Created by Jonathan on 08/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSListParameterInputViewController.h"
#import "MGSListParameterPlugin.h"

// class extension
@interface MGSListParameterInputViewController()
- (void)setSelectedItem:(id)item;
@end

@implementation MGSListParameterInputViewController
/*
 
 init  
 
 */
- (id)init
{
	if ((self = [super initWithNibName:@"ListParameterInputView"])) {
	}
	return self;
}


/*
 
 awake from nib
 
 */
- (void)awakeFromNib
{
	[super awakeFromNib];
	
	_arrayController = [[NSArrayController alloc] init];

	// observe arraycontroller
	[_arrayController addObserver:self forKeyPath:@"selectedObjects" options:NSKeyValueObservingOptionNew context:MGSSelectedObjectsContext];

	[[_tableView tableColumnWithIdentifier:@"value"] bind:NSValueBinding toObject:_arrayController withKeyPath:@"arrangedObjects" options:nil]; 
}

/*
 
 observe value for key path
 
 */
- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
	#pragma unused(keyPath)
	#pragma unused(object)
	#pragma unused(context)
	#pragma unused(change)
	
	if (context == MGSSelectedObjectsContext) {
		NSArray *array = [_arrayController selectedObjects];
		if ([array count] > 0) {
			self.parameterValue = [array objectAtIndex:0];
		} 
	}
}

/*
 
 initialise from plist
 
 */
- (void)initialiseFromPlist
{
	[_arrayController setSelectsInsertedObjects:NO];
	
	_defaultValue = [self.plist objectForKey:MGSScriptKeyDefault withDefault:@""];
	NSArray *array = [self.plist objectForKey:MGSKeyList withDefault:[[NSArray alloc] init]];
	for (id item in array) {
		[_arrayController addObject:item];
	}
	
	[self resetToDefaultValue];
	
	self.label = NSLocalizedString(@"Select an item from the list", @"label text");
}

/*
 
 override reset to default value
 
 */
- (void)resetToDefaultValue
{
	if (_defaultValue) {
		[self setSelectedItem:_defaultValue];
	} 
}

/*
 
 set selected item
 
 */
- (void)setSelectedItem:(id)item
{
	if (![item isKindOfClass:[NSString class]]) {
		return;
	}
	
	[self commitEditing];
	
	for (NSString *aString in [_arrayController arrangedObjects]) {
		if ([item isEqualToString:aString]) {
			[_arrayController setSelectedObjects:[NSArray arrayWithObject:aString]];
			break;
		}
	}	
	
	NSUInteger idx = [_arrayController selectionIndex];
	if (idx != NSNotFound) {
		[_tableView scrollRowToVisible:idx];
	}
}

/*
 
 set parameter value
 
 */
- (void)setParameterValue:(id)newValue
{
    if ([self validateParameterValue:newValue]) {
        [super setParameterValue:newValue];
        [self setSelectedItem:newValue];
    }
}

/*
 
 - validateParameterValue:
 
 */
- (BOOL)validateParameterValue:(id)newValue
{
#pragma unused(newValue)
    
    BOOL isValid = NO;
    
    if ([newValue isKindOfClass:[NSString class]]) {

        for (NSString *aString in [_arrayController arrangedObjects]) {
            if ([newValue isEqualToString:aString]) {
                isValid = YES;
                break;
            }
        }
    }
    
    return isValid;
}

/*
 
 can drag height override
 
 */
- (BOOL)canDragHeight
{
	return YES;
}
@end
