//
//  NSObject_Mugginsoft.h
//  Mother
//
//  Created by Jonathan on 28/03/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSObjectStyler.h"

/*
 
 category on NSObject
 
 */
@interface NSObject (Mugginsoft) 
- (BOOL)boolValue;
- (NSString *)aStringRepresentation;
- (NSString *)descriptionWithDepth:(NSUInteger)depth depthString:(NSString *)depthString;
- (NSString *)descriptionWithDepthString:(NSString *)depthString;
- (NSAttributedString *)mgs_attributedDescriptionWithStyle:(NSDictionary *)styleDict;
- (void)mgs_associateValue:(id)value withKey:(void *)key;
- (void)mgs_weaklyAssociateValue:(id)value withKey:(void *)key;
- (id)mgs_associatedValueForKey:(void *)key;
@end
