//
//  MGSRequestTabScrollView.h
//  Mother
//
//  Created by Jonathan on 28/10/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol MGSRequestTabScrollView 
- (void)view:(NSView *)view willResizeSubviewsWithOldSize:(NSSize)oldBoundsSize;
- (void)view:(NSView *)view didResizeSubviewsWithOldSize:(NSSize)oldBoundsSize;
@end

@class MGSRequestViewController;

@interface MGSRequestTabScrollView : NSScrollView {
	IBOutlet id delegate;
}

- (void)sizeDocumentWidthForRequestViewController:(MGSRequestViewController *)requestViewController withOldSize:(NSSize)oldBoundsSize;
- (void)resetDocumentWidthForRequestViewController:(MGSRequestViewController *)requestViewController withOldSize:(NSSize)oldBoundsSize;

@end
