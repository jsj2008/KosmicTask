//
//  EMKeychainItem_Mugginsoft.m
//  Mother
//
//  Created by Jonathan on 31/03/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "EMKeychainItem_Mugginsoft.h"


@implementation EMKeychainItem (Mugginsoft)

- (BOOL)setDescription:(NSString *)value
{
	//[self willChangeValueForKey:@"label"];
	//[myLabel autorelease];
	//myLabel = [newLabel copy];
	//[self didChangeValueForKey:@"label"];
	
	return [self modifyAttributeWithTag:kSecDescriptionItemAttr toBeString:value];
}

@end
