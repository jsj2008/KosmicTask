//
//  NSIndexPath+Mugginsoft.h
//
//  Created by Johnnie Walker on 29/10/2008.
//
//  Public Domain

#import <Foundation/Foundation.h>

/*

 NSIndexPath *idp = [[[NSIndexPath indexPathWithIndex:1] indexPathByAddingIndex:2] indexPathByAddingIndex:3];
 NSLog(@"idp: %@",idp);
 NSLog(@"[idp allIndexes]: %@",[idp allIndexes]);   
 NSLog(@"[NSIndexPath indexPathWithIndexes:[idp allIndexes]]: %@",[NSIndexPath indexPathWithIndexes:[idp allIndexes]]);
 NSAssert([idp isEqual:[NSIndexPath indexPathWithIndexes:[idp allIndexes]]],@"Indexes don't match");

 */

@interface NSIndexPath (Mugginsoft)
+ (NSIndexPath *)indexPathWithIndexes:(NSArray *)indexes;
- (NSIndexPath *)initWithIndexes:(NSArray *)indexes;
- (NSArray *)allIndexes;
@end
