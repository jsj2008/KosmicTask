//
//  NSIndexPath+Mugginsoft.m
//
//  Created by Johnnie Walker on 29/10/2008.
//
//  Public Domain

#import "NSIndexPath+Mugginsoft.h"

@implementation NSIndexPath (Mugginsoft)
+ (NSIndexPath *)indexPathWithIndexes:(NSArray *)indexes
{
    return [[[NSIndexPath alloc] initWithIndexes:indexes] autorelease];
}

- (NSIndexPath *)initWithIndexes:(NSArray *)indexes
{
    NSUInteger idx[[indexes count]];
    for (NSUInteger i=0; i<[indexes count]; i++) {
        idx[i] = [[indexes objectAtIndex:i] integerValue];      
    }

    return [self initWithIndexes:idx length:[indexes count]];
}

- (NSArray *)allIndexes
{
    NSMutableArray *indexes = [NSMutableArray arrayWithCapacity:[self length]];
    for (NSUInteger i=0; i<[self length]; i++) {
        [indexes addObject:[NSNumber numberWithInteger:[self indexAtPosition:i]]];
    }
    return [[indexes copy] autorelease];
}
@end
