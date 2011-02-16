//
//  MGSNegotiate.h
//  KosmicTask
//
//  Created by Jonathan on 20/12/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MGSNetNegotiator : NSObject <NSCopying> {
	NSMutableDictionary *dict;
}
//+ (id)negotiatorWithAuthenticationAndTLSSecurity;
+ (id)negotiatorWithTLSSecurity;
- (id)initWithDictionary:(NSDictionary *)aDictionary;
- (BOOL)TLSSecurityRequested;
//- (void)setRequireAuthentication:(BOOL)aBool;
- (void)setSecurityType:(NSString *)aString;
- (NSDictionary *)dictionary;

@end
