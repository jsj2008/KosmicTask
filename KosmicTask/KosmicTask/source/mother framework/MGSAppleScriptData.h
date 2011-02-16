//
//  MGSAppleScriptData.h
//  Mother
//
//  Created by Jonathan on 10/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define useNDScript
//#define useNDAppleScriptObject

#ifdef useNDScript

#import "NDScript/NDScript.h"
#import "NDScript/NDScriptContext_Mugginsoft.h"

#else

#import "NDAppleScriptObject.h"
#import "NSAppleEventDescriptor+NDAppleScriptObject.h"

#endif

@interface MGSAppleScriptData : NDScriptData {

}

@end
