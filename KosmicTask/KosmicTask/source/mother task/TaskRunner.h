//
//  TaskRunner.h
//  KosmicTask
//
//  Created by Jonathan on 29/04/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSTaskPlist.h"
#import "MGSScriptPlist.h"
#import "MGSError.h"
#import "NSError_Mugginsoft.h"
#import "NSString_Mugginsoft.h"
#import "NSPropertyListSerialization_Mugginsoft.h"
#import "MGSScriptRunner.h"
#import "MGSScriptExecutorManager.h"
#import "MGSExternalScriptRunner.h"
#import "KosmicTaskController.h"

extern int MGSTaskRunnerMain (int argc, const char * argv[]);
