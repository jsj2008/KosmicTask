//
//  MGSResourceImages.h
//  Mother
//
//  Created by Jonathan on 16/11/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *MGSImageCollectionKeyImage;
extern NSString *MGSImageCollectionKeyName;
extern NSString *MGSImageCollectionKeyLocation;
extern NSString *MGSResourceGroupIcons;


@interface MGSResourceImages : NSObject {
}
+ (NSMutableArray *)imageDictionaryArrayAtPath:(NSString *)path;

@end
