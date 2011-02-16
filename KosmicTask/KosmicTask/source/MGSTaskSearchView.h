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
	id delegate;
}

@property (assign) id <MGSViewDelegateProtocol> delegate;
@end
