//
//  MGSEditWindow.h
//  Mother
//
//  Created by Jonathan on 01/09/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSActionExecuteWindow.h"

@protocol MGSEditNSWindowDelegate
@required
- (void)documentEdited:(BOOL)flag forWindow:(NSWindow *)window;
@end

@interface MGSEditWindow : MGSActionExecuteWindow {

}

@end
