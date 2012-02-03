//
//  MGSTextView.h
//  KosmicTask
//
//  Created by Jonathan on 21/10/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MGSTextView : NSTextView {
	NSDictionary *consoleAttributes;
}

@property (copy) NSDictionary *consoleAttributes;

- (void)setText:(NSString *)text append:(BOOL)append options:(NSDictionary *)options;
@end
