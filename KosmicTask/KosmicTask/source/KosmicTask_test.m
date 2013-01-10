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
#import "NSArray_Mugginsoft.h"
#import "MGSLanguageFunctionDescriptor.h"

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
    NSUInteger val = [KosmicTaskController fourCharToInteger:fourChar];
    STAssertEquals((NSUInteger)val, (NSUInteger)1349734246, @"%@ Four char string to integer", fourChar);
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
    
    // string methods
    NSArray *components = @[ @"this", @"is a", @"really trivial sort", @"of", @"example, yes?"];
    NSArray *invalidComponents = @[ @"this\n", @"\tis a", @"really trivial sort", @"of", @"example, yes?"];
    
    NSString *componentTestTarget1 = [NSString stringWithFormat:@"/ %@\n / \t%@ / %@ / %@ / %@ /",
                                      [components objectAtIndex:0],
                                      [components objectAtIndex:1],
                                      [components objectAtIndex:2],
                                      [components objectAtIndex:3],
                                      [components objectAtIndex:4]
                                      ];
    NSString *componentTestTarget2 = [NSString stringWithFormat:@"/// %@\n / / \t%@ /  // %@ /// %@ / %@ // / /",
                                      [components objectAtIndex:0],
                                      [components objectAtIndex:1],
                                      [components objectAtIndex:2],
                                      [components objectAtIndex:3],
                                      [components objectAtIndex:4]
                                      ];
    STAssertTrue([[componentTestTarget1 mgs_minimalComponentsSeparatedByString:@"/"] count] == [components count], @"valid components");
    STAssertTrue([[componentTestTarget2 mgs_minimalComponentsSeparatedByString:@"/"] count] == [components count], @"valid components");
    STAssertTrue([[componentTestTarget1 mgs_minimalComponentsSeparatedByString:@"/"] isEqualToArray:components], @"valid components");
    STAssertTrue([[componentTestTarget2 mgs_minimalComponentsSeparatedByString:@"/"] isEqualToArray:components], @"valid components");
    STAssertFalse([[componentTestTarget2 mgs_minimalComponentsSeparatedByString:@"/"] isEqualToArray:invalidComponents], @"invalid components");
    STAssertFalse([[componentTestTarget2 mgs_minimalComponentsSeparatedByString:@"/"] isEqualToArray:invalidComponents], @"invalid components");
}

- (void)testArrayCategories
{
    NSIndexSet *indexSet =nil;
    
    // object indexes
    NSArray *array = @[@"one", @"two", @"three", @"four", @" one", @"two ", @"tree", @"for"];
    NSDictionary *indexSetDictionary = [array mgs_objectIndexes];
    NSArray *keys = [indexSetDictionary allKeys];
    STAssertTrue([array count] == [keys count], @"valid key count");
    for (NSString *key in keys) {
        indexSet = [indexSetDictionary objectForKey:key];
        STAssertTrue([indexSet count] == 1, @"valid index set count");
    }
    
    array = @[@"one", @"two", @"three", @"four", @"two", @"five", @"one", @"three"];
    indexSetDictionary = [array mgs_objectIndexes];
    keys = [indexSetDictionary allKeys];
    STAssertTrue([keys count] == 5, @"valid key count");
    indexSet = [indexSetDictionary objectForKey:@"one"];
    STAssertTrue([indexSet count] == 2, @"valid index set count");
    indexSet = [indexSetDictionary objectForKey:@"two"];
    STAssertTrue([indexSet count] == 2, @"valid index set count");
    indexSet = [indexSetDictionary objectForKey:@"three"];
    STAssertTrue([indexSet count] == 2, @"valid index set count");
    indexSet = [indexSetDictionary objectForKey:@"four"];
    STAssertTrue([indexSet count] == 1, @"valid index set count");
    indexSet = [indexSetDictionary objectForKey:@"five"];
    STAssertTrue([indexSet count] == 1, @"index set count");
    
}

- (void)testTaskCodeGeneration
{
    /* need a valid script object for this to work
    MGSLanguageFunctionDescriptor *descriptor = [[MGSLanguageFunctionDescriptor alloc] init];
    descriptor.functionArgumentCase = kMGSFunctionArgumentInputCase;
    descriptor.functionArgumentStyle = kMGSFunctionArgumentHyphenated;
    NSMutableArray *array = [NSMutableArray arrayWithObjects:@"one", @"two", @"three", @"four", @"two", @"three ", @"one", @"three", nil];
    [descriptor makeObjectsUnique:array];
    STAssertTrue([[array objectAtIndex:0] isEqualToString:@"one-1"], @"valid content");
    STAssertTrue([[array objectAtIndex:1] isEqualToString:@"two-1"], @"valid content");
    STAssertTrue([[array objectAtIndex:2] isEqualToString:@"three-1"], @"valid content");
    STAssertTrue([[array objectAtIndex:3] isEqualToString:@"four"], @"valid content");
    STAssertTrue([[array objectAtIndex:4] isEqualToString:@"two-2"], @"valid content");
    STAssertTrue([[array objectAtIndex:5] isEqualToString:@"three-2"], @"valid content");
    STAssertTrue([[array objectAtIndex:6] isEqualToString:@"one-2"], @"valid content");
    STAssertTrue([[array objectAtIndex:6] isEqualToString:@"three-3"], @"valid content");
     */
}

- (void)testObjCLiteralSyntax
{
    NSArray *array = @[ @"Hello", @'Z', @42, @42U, @42L, @42LL, @3.141592654F, @3.1415926535, @YES, @NO, @{ @"yes" : @YES, @"NO" : @NO } ];

    id item = [array objectAtIndex:0];

#if __LP64__
    item = array[0];    // fails in 32 bit
#endif
    
    NSMutableArray *marray = [NSMutableArray arrayWithObjects: @"Hello", @'Z', @42, @42U, @42L, @42LL, @3.141592654F, @3.1415926535, @YES, @NO, @{ @"yes" : @YES, @"NO" : @NO } , nil];
    item = [marray objectAtIndex:0];
    
#if __LP64__    
    marray[0] = @"Sayonara";    // fails in 32 bit
#endif
    
}
@end
