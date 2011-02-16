// http://jongampark.wordpress.com/2008/01/26/a-simple-objectie-c-class-for-checking-if-a-specific-process-is-running/
#import "JAProcessInfo.h"

#include <assert.h>
#include <errno.h>
#include <stdbool.h>
#include <sys/sysctl.h>


@interface NSDictionary (JAProcessInfo)
- (void)jap_addDescendentsForObject:(id)object toSet:(NSMutableSet *)descendents;
@end

typedef struct kinfo_proc kinfo_proc;

@implementation JAProcessInfo
- (id) init
{
    self = [super init];
	
    if (self != nil)
    {
        numberOfProcesses = -1; // means "not initialized"
        processList = NULL;
		
		[self obtainFreshProcessList];
    }
	
    return self;
}

- (int)numberOfProcesses
{
    return numberOfProcesses;
}

- (void)setNumberOfProcesses:(int)num
{
    numberOfProcesses = num;
}

/*
 
 see http://developer.apple.com/mac/library/qa/qa2001/qa1123.html
 
 */
- (int)getBSDProcessList:(kinfo_proc **)procList
   withNumberOfProcesses:(size_t *)procCount
{
    int             err;
    kinfo_proc *    result;
    bool            done;
    static const int    name[] = { CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0 };
    size_t          length;
	
    // a valid pointer procList holder should be passed
    assert( procList != NULL );
    // But it should not be pre-allocated
    assert( *procList == NULL );
    // a valid pointer to procCount should be passed
    assert( procCount != NULL );
	
    *procCount = 0;
	
    result = NULL;
    done = false;
	
    do
    {
        assert( result == NULL );
		
        // Call sysctl with a NULL buffer to get proper length
        length = 0;
        err = sysctl((int *)name,(sizeof(name)/sizeof(*name))-1,NULL,&length,NULL,0);
        if( err == -1 )
            err = errno;
		
        // Now, proper length is optained
        if( err == 0 )
        {
            result = malloc(length);
            if( result == NULL )
                err = ENOMEM;   // not allocated
        }
		
        if( err == 0 )
        {
            err = sysctl( (int *)name, (sizeof(name)/sizeof(*name))-1, result, &length, NULL, 0);
            if( err == -1 )
                err = errno;
			
            if( err == 0 )
                done = true;
            else if( err == ENOMEM )
            {
                assert( result != NULL );
                free( result );
                result = NULL;
                err = 0;
            }
        }
    } while ( err == 0 && !done );
	
    // Clean up and establish post condition
    if( err != 0 && result != NULL )
    {
        free(result);
        result = NULL;
    }
	
    *procList = result; // will return the result as procList
    if( err == 0 )
        *procCount = length / sizeof( kinfo_proc );
	
    assert( (err == 0) == (*procList != NULL ) );
	
    return err;
}

/*
 
 - obtainFreshProcessList
 
 */
- (void)obtainFreshProcessList
{
    size_t i;
    kinfo_proc *allProcs = 0;
    size_t numProcs;
    NSString *procName;
	
    int err =  [self getBSDProcessList:&allProcs withNumberOfProcesses:&numProcs];
    if( err )
    {
        numberOfProcesses = -1;
        processList = NULL;
		
        return;
    }
	
    // Construct an array for ( process name )
    processList = [NSMutableArray arrayWithCapacity:numProcs];
    for( i = 0; i < numProcs; i++ )
    {
		// note declaration of p_comm[MAXCOMLEN+1]
        procName = [NSString stringWithFormat:@"%s", allProcs[i].kp_proc.p_comm];
        [processList addObject:procName];
    }
	
    [self setNumberOfProcesses:numProcs];
	
    // NSLog(@"# of elements = %d total # of process = %d\n",
    //         [processArray count], numProcs );
	
    free( allProcs );
	
}

/*
 
 - findProcessWithName:
 
 */
- (BOOL)findProcessWithName:(NSString *)procNameToSearch
{
    int idx;
	
    idx = [processList indexOfObject:[procNameToSearch substringToIndex:MAXCOMLEN]];
	
    if( idx == NSNotFound )
        return NO;
    else
        return YES;
}

/*
 
 - descendentsOfPID:
 
 */
- (NSArray *)descendentsOfPID:(int)parentPID
{
    kinfo_proc *allProcs = 0;
    size_t numProcs;
	
    int err =  [self getBSDProcessList:&allProcs withNumberOfProcesses:&numProcs];
    if( err )
    {
        numberOfProcesses = -1;
        processList = NULL;
		
        return nil;
    }
	
	NSMutableDictionary * pidDict = [NSMutableDictionary dictionaryWithCapacity:500];
	
	// build a pid dictionary
    for (size_t i = 0; i < numProcs; i++)
    {
		pid_t process = allProcs[i].kp_proc.p_pid;
		pid_t processParent = allProcs[i].kp_eproc.e_ppid;
		
		// process will be unique
        [pidDict setObject:[NSNumber numberWithInt:processParent] forKey:[NSNumber numberWithInt:process]];
    }
			 
	// extract all descendents of parentPID
	NSMutableSet *descendents = [NSMutableSet setWithCapacity:100];
	[pidDict jap_addDescendentsForObject:[NSNumber numberWithInt:parentPID] toSet:descendents];
	

	free( allProcs );
	
	return [descendents allObjects];
}

@end

@implementation NSDictionary (JAProcessInfo)

/*
 
 - jap_addDescendentsForObject:
 
 */
- (void)jap_addDescendentsForObject:(id)object toSet:(NSMutableSet *)descendents
{
	// keys for object
	NSArray *newObjects = [self allKeysForObject:object];
	
	if ([newObjects count] > 0) {
		for (id newObject in newObjects) {
			[self jap_addDescendentsForObject:newObject toSet:descendents];
		}
		[descendents addObjectsFromArray:newObjects];
	}
}
@end

