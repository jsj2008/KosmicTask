//
//  MGSChildScrollView.h
//  KosmicTask
//
//  Created by Mitchell Jonathan on 26/06/2012.
//  Copyright (c) 2012 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MGSChildScrollView : NSScrollView {
@private
    BOOL embedded;
}
@property BOOL embedded;

@end
