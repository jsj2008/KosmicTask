//
//  MGSWaitView.h
//  Mother
//
//  Created by Jonathan on 12/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSFilledView.h"

@interface MGSWaitView : MGSFilledView {
	IBOutlet NSProgressIndicator *_progressIndicator;
}
- (void)startProgressAnimation;
- (void)stopProgressAnimation;

@end
