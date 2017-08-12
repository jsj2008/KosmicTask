//
//  MGSOutputRequestView.h
//  KosmicTask
//
//  Created by Jonathan on 30/12/2009.
//  Copyright 2009 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSViewDelegateProtocol.h"

@interface MGSOutputRequestView : NSView {
	@private
	__weak id delegate;
}

@property (weak) id <MGSViewDelegateProtocol> delegate;
@end
