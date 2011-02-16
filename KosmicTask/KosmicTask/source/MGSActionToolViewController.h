//
//  MGSActionToolViewController.h
//  Mother
//
//  Created by Jonathan on 14/02/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSToolViewController.h"

@interface MGSActionToolViewController : MGSToolViewController {
}


- (IBAction)newAction:(id)sender;
- (IBAction)duplicateAction:(id)sender;
- (IBAction)deleteAction:(id)sender;
- (IBAction)editAction:(id)sender;
- (void)initialiseForWindow:(NSWindow *)window;

@end
