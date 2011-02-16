//
//  MGSResultFormat.h
//  KosmicTask
//
//  Created by Jonathan on 04/04/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MGSResultFormat : NSObject {

}

+ (NSArray *)fileDataKeys;
+ (NSArray *)dataKeys;
+ (NSArray *)errorKeys;
+ (NSArray *)infoKeys;
+ (NSArray *)inlineStyleKeys;
+ (NSArray *)styleNameKeys;
+ (NSArray *)styleNamesKeys;
+ (NSArray *)dictStyleFilterKeys;
+ (NSArray *)dictKeyStyleFilterKeys;
+ (NSString *)formatResultKey:(NSString *)key;

@end
