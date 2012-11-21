//
//  KosmicTask_test.m
//  KosmicTask
//
//  Created by Jonathan on 12/11/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "KosmicTask_test.h"
#import "KosmicTaskController.h"
#import "NSString_Mugginsoft.h"

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

- (void)testStringCategories
{
    // UUID
    STAssertTrue([@"DB00EC6E-F96D-4CA4-B2E9-B8AB4324B791" mgs_isUUID], @"valid UUID");
    
    STAssertFalse([@"DB00EC6E_F96D-4CA4-B2E9-B8AB4324B791" mgs_isUUID], @"invalid UUID");
    STAssertFalse([@"D00EC6E-F96D-4CA4-B2E9-B8AB4324B791" mgs_isUUID], @"invalid UUID");
    STAssertFalse([@"D00EC6E-F96-4CA4-B2E9-B8AB4324B791" mgs_isUUID], @"invalid UUID");
    STAssertFalse([@"D00EC6E-F96D-4CA4-B29-B8AB4324B791" mgs_isUUID], @"invalid UUID");
    STAssertFalse([@"D00EC6E-F96D-4CA4-B299-8AB4324B791" mgs_isUUID], @"invalid UUID");
    STAssertFalse([@"D0$EC6E-F96D-4CA4-B299-8AB4324B791" mgs_isUUID], @"invalid UUID");
    
    // URL
    STAssertTrue([@"http://www.mugginsoft.com" mgs_isURL], @"valid URL");
    STAssertTrue([@"https://www.mugginsoft.com" mgs_isURL], @"valid URL");
    STAssertTrue([@"www.mugginsoft.com" mgs_isURL], @"valid URL");
    STAssertTrue([@"mugginsoft.com" mgs_isURL], @"valid URL");
    STAssertTrue([@"mugginsoft.museum" mgs_isURL], @"valid URL");

    STAssertFalse([@"http://www.mugginsoft.c" mgs_isURL], @"invalid URL");
    STAssertFalse([@"http://#www.mugginsoft.com" mgs_isURL], @"invalid URL");
    
    // IP address
    STAssertTrue([@"192.168.0.23" mgs_isIPAddress], @"valid IP");
    STAssertTrue([@"fe80::cabc:c8ff:fea5:d5db" mgs_isIPAddress], @"valid IP");

    STAssertFalse([@"192.168.o.23" mgs_isIPAddress], @"invalid IP");
    STAssertFalse([@"192.168.023" mgs_isIPAddress], @"invalid IP");
    STAssertFalse([@"fe80:cabc:c8ff:fea5:d5db" mgs_isIPAddress], @"invalid IP");
    STAssertFalse([@"fe8o:cabc:c8ff:fea5:d5db" mgs_isIPAddress], @"invalid IP");
}
@end
