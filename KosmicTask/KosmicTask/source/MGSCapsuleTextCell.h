//
//  MGSCapsuleTextCell.h
//  Mother
//
//  Created by Jonathan on 21/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MGSCapsuleTextCell : NSTextFieldCell {
	BOOL _capsuleHasShadow;
	BOOL _sizeCapsuleToFit;
}

@property BOOL capsuleHasShadow;
@property BOOL sizeCapsuleToFit;
@end
