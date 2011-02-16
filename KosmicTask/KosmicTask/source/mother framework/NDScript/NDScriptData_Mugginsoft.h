//
//  NDScriptData_Mugginsoft.h
//  Mother
//
//  Created by Jonathan on 10/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NDScriptData (Mugginsoft)

// JM 18-03-08 GC dispose
-(void)dispose;


// JM 18-03-08
- (NSAttributedString *)attributedSource;

@end
