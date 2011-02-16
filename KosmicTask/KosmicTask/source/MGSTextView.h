//
//  MGSTextView.h
//  KosmicTask
//
//  Created by Jonathan on 21/10/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MGSTextView : NSTextView {
	NSDictionary *forcedTypingAttributes;
}

@property (copy) NSDictionary *forcedTypingAttributes;

@end
