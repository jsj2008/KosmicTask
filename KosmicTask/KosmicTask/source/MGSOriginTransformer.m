//
//  MGSOriginTransformer.m
//  KosmicTask
//
//  Created by Jonathan on 29/06/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSOriginTransformer.h"
#import "MGSImageManager.h"


@implementation MGSOriginTransformer

/*
 
 transformed value class
 
 */
+ (Class)transformedValueClass 
{ 
	return [NSImage class]; 
}
/*
 
 allows reverse transform
 
 */
+ (BOOL)allowsReverseTransformation 
{ 
	return NO; 
}

/*
 
 transformed value
 
 */
- (id)transformedValue:(id)value {
	NSImage *image = nil;
	
	if ([value isKindOfClass:[NSString class]]) {
		if ([(NSString *)value isEqualToString:@"User"]) {
			image = [[(MGSImageManager *)[MGSImageManager sharedManager] user] copy];
		} else {
			image = [NSImage imageNamed:@"GearSmall"];
		}
	}
	
	return image;
}

@end
