//
//  MGSView.h
//  Mother
//
//  Created by Jonathan on 16/10/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSViewDelegateProtocol.h"

@interface MGSView : NSView {
	IBOutlet __weak id delegate;
}
@property (weak) id <MGSViewDelegateProtocol> delegate;
@end
