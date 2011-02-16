//
//  MGSLabelTextCell.h
//  Mother
//
//  Created by Jonathan on 21/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *MGSLabelTextCellStringKey;
extern NSString *MGSLabelTextCellLabelIndexKey;

@interface MGSLabelTextCell : NSTextFieldCell {
	NSInteger _labelIndex;
}
@property NSInteger labelIndex;
@end
