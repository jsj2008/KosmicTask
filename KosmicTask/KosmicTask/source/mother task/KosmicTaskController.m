//
//  KosmicTaskController.m
//  KosmicTask
//
//  Created by Jonathan on 21/05/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "KosmicTaskController.h"
#import "MGSScriptRunner.h"
#import "NSString_Mugginsoft.h"
#import "MGSTempStorage.h"

/*
 
 QuietLog
 
 */
void QuietLog (NSString *format, ...) {
    va_list argList;
    
    va_start (argList, format);
    NSString *message = [[NSString alloc] initWithFormat: format arguments: argList]; // autorelease if not ARC
    va_end (argList);
    
    fprintf (stderr, "%s\n", [message UTF8String]);
    
}

@implementation KosmicTaskController

static id mgs_sharedController;

@synthesize keepTaskAlive, resultObject;

/*
 
 shared controller singleton
 
 */
+ (id)sharedController 
{
	@synchronized(self) {
		if (nil == mgs_sharedController) {
			id temp = [[self alloc] init];  // assignment occurs below in allocWithZone
            (void)temp;
		}
	}
	return mgs_sharedController;
}

/*
 
 alloc with zone for singleton
 
 */
+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self) {
        if (mgs_sharedController == nil) {
            mgs_sharedController = [super allocWithZone:zone];
            return mgs_sharedController;  // assignment and return on first allocation
        }
    }
    return nil; //on subsequent allocation attempts return nil
} 

/*
 
 + log
 
 */
+ (void)log:(NSString *)value
{
    QuietLog(@"%@", value);
}

/*
 
 + qlog
 
 */
+ (void)qlog:(NSString *)value
{
    QuietLog(@"%@", value);
}

/*
 
 + vlog
 
 */
+ (void)vlog:(NSString *)value
{
    NSLog(@"%@", value);
}

/*
 
 + stopTask:
 
 */
+ (void)stopTask:(id)result
{
	[[self sharedController] stopTask:result];
}

/*
 
 + setKeepTaskAlive:
 
 */
+ (void)setKeepTaskAlive:(BOOL)aBool
{
	[[self sharedController] setKeepTaskAlive:aBool];
}

/*
 
 + keepTaskAlive
 
 */
+ (BOOL)keepTaskAlive
{
    return [[self sharedController] keepTaskAlive];
}
/*
 
 + keepTaskRunning
 
 */
+ (void)keepTaskRunning
{
	[[self sharedController] setKeepTaskAlive:YES];
}

/*
 
 + fourCharToInteger:
 
 */
+ (NSUInteger)fourCharToInteger:(NSString *)fourChar
{
    // evaluate multi char constant as an integer
    // ie: 'abcd'
    NSUInteger val = 0;
    if ([fourChar length] != 4) return val;
    val = [fourChar characterAtIndex:0] << 24;
    val += [fourChar characterAtIndex:1] << 16;
    val += [fourChar characterAtIndex:2] << 8;
    val += [fourChar characterAtIndex:3] << 0;
    
    return val;
}

/*
 
 + tempPathWithSuffix:
 
 */
+ (NSString *)tempFileWithName:(NSString *)suffix
{
	return [[self sharedController] tempFileWithName:suffix];
}

/*
 
 + resultPathWithSuffix:
 
 */
+ (NSString *)resultFileWithName:(NSString *)suffix
{
	return [[self sharedController] resultFileWithName:suffix];
}

/*
 
 copy with zone for singleton
 
 */
- (id)copyWithZone:(NSZone *)zone
{
#pragma unused(zone)
    return self;
}


/*
 
 - init
 
 */
- (id)init
{
	self = [super init];
	if (self) {
		keepTaskAlive = NO;
		temporaryPaths = [NSMutableArray new];
	}
	
	return self;
}

/*
 
 - setKeepTaskAlive:
 
 */
- (void)setKeepTaskAlive:(BOOL)aBool
{
	keepTaskAlive = aBool;
	if (!keepTaskAlive) {
			
		id appDelegate = [NSApp delegate];		
		NSAssert([appDelegate conformsToProtocol:@protocol(MGSScriptRunner)], @"app delegate cannot stop task", nil);

		// stop the task
		[appDelegate stopTask:self.resultObject];
	
	}
}


/*
 
 - stopTask:
 
 */
- (void)stopTask:(id)result
{
	self.resultObject = result;
	self.keepTaskAlive = NO;
}

/*
 
 - tempPathWithSuffix:
 
 */
- (NSString *)tempFileWithName:(NSString *)suffix
{
	return [self resultFileWithName:suffix];
	
}

/*
 
 - resultPathWithSuffix:
 
 */
- (NSString *)resultFileWithName:(NSString *)suffix
{
	// MGSNetAttachment writes its temp files as preamble.filename
	// hence we do the same
	suffix = [NSString stringWithFormat:@"%@.%@", MGSKosmicTempFileNamePrefix, suffix];
	
	// this path should be deleted when the task ends
	NSString *path = [NSString mgs_stringWithCreatedTempFilePathSuffix:suffix];
	
	[temporaryPaths addObject:path];
	
	return path;
}

/*
 
 - scratchPaths
 
 */
- (NSArray *)scratchPaths
{
	return temporaryPaths;
}

/*
 
 - log
 
 */
- (void)log:(NSString *)value
{
    [[self class] log:value];
}

/*
 
 + qlog
 
 */
- (void)qlog:(NSString *)value
{
    [[self class] qlog:value];
}

/*
 
 - vlog
 
 */
- (void)vlog:(NSString *)value
{
    [[self class] vlog:value];
}
@end
