//
//  MGSTaskSearchView.h
//  KosmicTask
//
//  Created by Jonathan on 14/01/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSViewDelegateProtocol.h"

@interface MGSTaskSearchView : NSView {
@private
	__weak id delegate;
}

@property (weak) id <MGSViewDelegateProtocol> delegate;
@end
