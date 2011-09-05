//
//  NSBundle_Mugginsoft.m
//  Mother
//
//  Created by Jonathan on 28/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "NSBundle_Mugginsoft.h"
#import "MGSPath.h"

@implementation NSBundle (Mugginsoft)


/*
 
 bundle info.plist object for key
 
 */
+(id) mainBundleInfoObjectForKey:(NSString *)key
{
	NSDictionary *info = [[self mainBundle] localizedInfoDictionary];
	id object = [info objectForKey:key];
    if (object) {
        return object;
	}
	
	info = [[self mainBundle] infoDictionary];
    return [info objectForKey:key];
}



@end
