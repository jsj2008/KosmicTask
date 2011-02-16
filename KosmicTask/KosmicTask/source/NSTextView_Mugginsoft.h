//
//  NSTextView_Mugginsoft.h
//  Mother
//
//  Created by Jonathan on 10/04/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSTextView (Mugginsoft)
- (void)addStringAndScrollToVisible:(NSString *)string;
- (void)addString:(NSString *)string;
- (void)setLineWrap:(BOOL)wrap;
- (IBAction)toggleLineWrapping:(id)sender;
- (IBAction)increaseFontSize:(id)sender;
- (IBAction)decreaseFontSize:(id)sender;
@end
