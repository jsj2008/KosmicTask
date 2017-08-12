//
//  MGSToolViewController.h
//  KosmicTask
//
//  Created by Jonathan on 01/01/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSToolbarController.h"
#import "MGSToolbarItem.h"

@interface MGSToolViewController :  NSObject {
	@private
	__weak id delegate;
	IBOutlet NSView *__weak view;
}

@property (weak) id <MGSToolbarDelegate, MGSToolbarItemDelegate> delegate;
@property (weak) NSView *view;

@end
