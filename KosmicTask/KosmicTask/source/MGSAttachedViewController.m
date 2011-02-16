//
//  MGSAttachedViewController.m
//  Mother
//
//  Created by Jonathan on 26/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSAttachedViewController.h"


@implementation MGSAttachedViewController

@synthesize text = _text;
@synthesize textColor = _textColor;

- (void)awakeFromNib
{
	//[textField bind:@"value" toObject:self withKeyPath:@"text" options:nil];
	[textField bind:@"textColor" toObject:self withKeyPath:@"textColor" options:nil];
}

- (void)setText:(NSString *)value
{
	_text = value;
	[textField setStringValue:_text];
	
	// size view to fit text
	NSRect maxRect = NSMakeRect(0, 0, 400, 800);
	NSSize cellSize = [[textField cell] cellSizeForBounds:maxRect];
	NSRect viewRect = [[self view] frame];
	viewRect.size.width = cellSize.width;
	viewRect.size.height = cellSize.height;
	[[self view] setFrame:viewRect];
}
// override
- (NSString *)nibName
{
	return @"AttachedView";
}
@end

