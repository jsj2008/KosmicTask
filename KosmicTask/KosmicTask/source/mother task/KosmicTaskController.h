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
+ (BOOL)keepTaskAlive;
+ (NSString *)tempFileWithName:(NSString *)suffix;
+ (NSString *)resultFileWithName:(NSString *)suffix;
+ (void)keepTaskRunning;
+ (NSUInteger)fourCharToInteger:(NSString *)fourChar;
+ (void)log:(NSString *)value;
+ (void)qlog:(NSString *)value;
+ (void)vlog:(NSString *)value;

- (NSString *)tempFileWithName:(NSString *)suffix;
- (NSString *)resultFileWithName:(NSString *)suffix;
- (void)stopTask:(id)result;
- (NSArray *)scratchPaths;
- (void)log:(NSString *)value;
- (void)qlog:(NSString *)value;
- (void)vlog:(NSString *)value;
@end
