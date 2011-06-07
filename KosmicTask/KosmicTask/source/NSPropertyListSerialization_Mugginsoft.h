//
//  NSPropertyListSerialization_Mugginsoft.h
//  Mother
//
//  Created by Jonathan on 10/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>



@interface NSPropertyListSerialization (Mugginsoft)
int myArray[2] = {1,2};
+ (id)coercePropertyList:(id)plist;
+ (NSDictionary *)coerceDictionary:(NSDictionary *)plist;
+ (NSArray *)coerceArray:(NSArray *)plist;
+ (id)coerceObject:(id)object;
+ (NSXMLDocument *)XMLDocumentFromPropertyList:(id)aPlist format:(NSString *)format errorDescription:(NSString **)errorString;
+ (BOOL)addPropertyList:(id)aPlist toXMLElement:(NSXMLElement *)parent withName:(NSString *)name errorDescription:(NSString **)errorString;
@end
