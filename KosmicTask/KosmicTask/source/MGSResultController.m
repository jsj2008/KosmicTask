//
//  MGSResultController.m
//  Mother
//
//  Created by Jonathan on 08/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSResultController.h"
#import "MGSTaskSpecifier.h"
#import "MGSResult.h"
#import "MLog.h"

@implementation MGSResultController

/*
 
 init
 
 */
- (id) init
{
	if ((self = [super init])) {
		[self setObjectClass:[MGSResult class]];	// add this class
		//[self setSelectsInsertedObjects:NO];	// crashes
	}
	return self;
}

/* 
 
 add a result
 
 */
/*
- (MGSResult *)addResult:(id)resultObject forAction:(MGSTaskSpecifier *)action
{
	MGSResult *result = [self newObject];
	result.object = resultObject;
	result.action = action;
	
	[self addObject:result];

	return result; 
}
*/
/*
 
 select a result
 
 */
/*
- (void)setSelectedResult:(MGSResult *)result
{
	[self setSelectedObjects:[NSArray arrayWithObject:result]];
}
*/

/*
 
 set nil value for key
 
 */
- (void)setNilValueForKey:(NSString *)key
{
	// if select null placeholder item in list then selectedIndex gets set to nil,
	// hence we end up here!
	if ([key isEqualToString:@"selectionIndex"]) {
		[self setValue:[NSNumber numberWithInteger:NSNotFound] forKeyPath:key];
	}
}

/*
 
 finalize
 
 */
- (void)finalize
{
#ifdef MGS_LOG_FINALIZE
	MLog(DEBUGLOG, @"finalized");
#endif
    
	[super finalize];
}

/*
 
 - dispose
 
 */
- (void)dispose
{
    for (MGSResult *result in [self arrangedObjects]) {
        [result releaseDisposable];
    }
}
@end
