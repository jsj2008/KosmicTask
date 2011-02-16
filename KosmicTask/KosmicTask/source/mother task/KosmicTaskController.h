//
//  KosmicTaskController.h
//  KosmicTask
//
//  Created by Jonathan on 21/05/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface KosmicTaskController : NSObject {
	BOOL keepTaskAlive;
	id resultObject;
	NSMutableArray *temporaryPaths;
}
@property BOOL keepTaskAlive;
@property (retain) id resultObject;

+ (void)stopTask:(id)result;
+ (id)sharedController;
+ (void)setKeepTaskAlive:(BOOL)aBool;
+ (NSString *)tempFileWithName:(NSString *)suffix;
+ (NSString *)resultFileWithName:(NSString *)suffix;
+ (void)stopTask:(id)result;
+ (void)keepTaskRunning;

- (NSString *)tempFileWithName:(NSString *)suffix;
- (NSString *)resultFileWithName:(NSString *)suffix;
- (void)stopTask:(id)result;
- (NSArray *)scratchPaths;
@end
