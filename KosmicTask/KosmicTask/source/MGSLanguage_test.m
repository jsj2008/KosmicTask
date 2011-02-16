//
//  MGSLanguage_test.m
//  KosmicTask
//
//  Created by Jonathan on 12/11/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSLanguage_test.h"
#import "MGSLanguage.h"

@interface MGSLanguage_test()
@end

/*
 
 see
 
 http://developer.apple.com/library/mac/#documentation/DeveloperTools/Conceptual/UnitTesting/1-Articles/CreatingTests.html%23//apple_ref/doc/uid/TP40002171-BBCBGHCJ
 
 */
@implementation MGSLanguage_test

/*
 
 tests must begin with test*
 
 */

- (void) setUp {}
- (void) tearDown {}


- (void)testTokeniseString
{

// #warning these tests are rubbish
	NSArray *passTests = [NSArray arrayWithObjects:
							[NSArray arrayWithObjects:@"", @" ", @"\n", @"\n\n\n \n \t \n ", nil],
							[NSArray arrayWithObjects:@"\"1\"", @"'", @"\"\"", @"'a'", @"\"a\"", @" 1 \n\n \t \t", nil],
							[NSArray arrayWithObjects:@"1 \"-2", @"1 '-2'", @"1 '-2'", @"'1' '-2'", @"\"1\" \"-2\"", @" \n\n \n \"1\" \t \"-2\" \n", nil],
							[NSArray arrayWithObjects:@"1 *2 \"x3", @"1 '2' 'x3\"", @"1 '2' 'x3", @"1 \"2\" \"x3\"", @"1 \"2\" \"x3", @"\n \t1 \"2\" \n \"x3 \t", nil],
					  nil];
	NSUInteger idx = 0;
	for (NSArray *testData in passTests) {
		
		// testData at allTests index = idx should parse into idx tokens
		for (NSString *theTest in testData) {
			NSMutableArray *tokens = [MGSLanguage tokeniseString:theTest];
			STAssertNotNil(tokens, @"Test index = %i", idx);
			STAssertTrue([tokens count] == idx, @"Test index = %i", idx);
		}
		idx++;
	}

}

@end
