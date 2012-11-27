//
//  MGSTextParameterPlugin.h
//  Mother
//
//  Created by Jonathan on 06/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSParameterPlugin.h"

enum _MGSTextParameterInputStyle {
	kMGSTextParameterInputStyleSingleLine = 0,
	kMGSParameterInputStyleMultiLine = 1
};
typedef NSInteger MGSTextParameterInputStyle;

extern NSString *MGSKeyAllowEmptyInput;
extern NSString *MGSKeyInputStyle;

@interface MGSTextParameterPlugin : MGSParameterPlugin {

}

@end
