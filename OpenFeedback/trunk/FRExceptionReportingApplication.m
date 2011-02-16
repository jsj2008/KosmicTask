/*
 * Copyright 2008, Jens Alfke, Torsten Curdt
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "FRExceptionReportingApplication.h"
#import "NSException+Callstack.h"

static void (*sExceptionReporter)(NSException*);

void MYSetExceptionReporter( void (*reporter)(NSException*) )
{
    sExceptionReporter = reporter;
}

void MYReportException( NSException *x, NSString *where, ... )
{
    va_list args;
    va_start(args,where);
    where = [[NSString alloc] initWithFormat: where arguments: args];
    va_end(args);
    if( sExceptionReporter ) {
        NSLog(@"Exception caught in %@:\n\t%@", where, x);
        sExceptionReporter(x);
    } else {
        NSLog(@"Exception caught in %@:\n\t%@\n%@",where, x, x.my_callStack);
    }
    [where release];
}


@implementation FRExceptionReportingApplication


static void report( NSException *x ) {
    [[NSApplication sharedApplication] reportException: x];
}

- (id) init
{
    self = [super init];
    if (self != nil) {
        MYSetExceptionReporter(&report);
    }
    return self;
}


- (void) reportException:(NSException *)x
{
    [super reportException: x];
    
	if (NO) {
		[[OpenFeedback sharedController] reportException:x];
	} else {
		[[OpenFeedback sharedController] performSelector:@selector(reportException:) withObject:x afterDelay:0];
	}
}


@end
