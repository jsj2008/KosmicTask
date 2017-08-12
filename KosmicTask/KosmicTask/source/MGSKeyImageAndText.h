//
//  MGSKeyObject.h
//  Mother
//
//  Created by Jonathan on 13/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSImageAndText.h"

@interface MGSKeyImageAndText : MGSImageAndText {
	id __unsafe_unretained _key;
}

@property (unsafe_unretained) id key;

@end
