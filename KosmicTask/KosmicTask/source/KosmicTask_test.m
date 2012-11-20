//
//  KosmicTask_test.m
//  KosmicTask
//
//  Created by Jonathan on 12/11/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "KosmicTask_test.h"
#import "KosmicTaskController.h"

/*
 common macros defined in SenTestingKit.h
 
 STAssertNotNil(a1, description, ...)
 STAssertTrue(expression, description, ...)
 STAssertFalse(expression, description, ...)
 STAssertEqualObjects(a1, a2, description, ...)
 STAssertEquals(a1, a2, description, ...)
 STAssertThrows(expression, description, ...)
 STAssertNoThrow(expression, description, ...)
 STFail(description, ...)

 */
@implementation KosmicTask_test

- (void) setUp {}
- (void) tearDown {}

- (void)testInit
{
    NSString *tester = @"YES";
    
    STAssertNotNil(tester, @"Test is nil");
}

- (void)testKosmicTaskController
{
    NSString *fourChar = @"PsOf";
    NSInteger val = [KosmicTaskController fourCharToInteger:fourChar];
    STAssertEquals(val, 1349734246, @"%@ Four char string to integer", fourChar);
}
@end
