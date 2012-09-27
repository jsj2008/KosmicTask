//
//  NSTextView_Mugginsoft.h
//  Mother
//
//  Created by Jonathan on 10/04/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSTextView (Mugginsoft)
- (void)mgs_addStringAndScrollToVisible:(NSString *)string;
- (void)mgs_addString:(NSString *)string;
- (void)mgs_setLineWrap:(BOOL)wrap;
- (IBAction)mgs_toggleLineWrapping:(id)sender;
- (IBAction)mgs_increaseFontSize:(id)sender;
- (IBAction)mgs_decreaseFontSize:(id)sender;
- (void)changeFont:(NSFont *)newFont;
@end
