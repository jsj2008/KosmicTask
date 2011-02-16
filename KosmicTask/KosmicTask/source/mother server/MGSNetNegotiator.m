//
//  MGSNegotiate.m
//  KosmicTask
//
//  Created by Jonathan on 20/12/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSNetNegotiator.h"
#import "MGSNetMessage.h"

@interface MGSNetNegotiator()
- (id)objectForKey:(id)key;
- (void)setObject:(id)object forKey:(id)key;
@end

@implementation MGSNetNegotiator

/*
 
 + negotiatorWithAuthenticationAndTLSSecurity
 
 */
/*+ (id)negotiatorWithAuthenticationAndTLSSecurity
{
	MGSNetNegotiator *negotiator = [[self alloc] initWithDictionary:nil];
	[negotiator setRequireAuthentication:YES];
	[negotiator setSecurityType:MGSNetMessageNegotiateSecurityTLS];

	return negotiator;
}*/
/*
 
 + negotiatorWithAuthenticationAndTLSSecurity
 
 */
+ (id)negotiatorWithTLSSecurity
{
	MGSNetNegotiator *negotiator = [[self alloc] initWithDictionary:nil];
	[negotiator setSecurityType:MGSNetMessageNegotiateSecurityTLS];
	
	return negotiator;
}
/*
 
 - init
 
 */
- (id)init
{
	return [self initWithDictionary:nil];
}
/*
 
 - initWithDictionary:
 
 designated initialiser
 
 */
- (id)initWithDictionary:(NSDictionary *)aDictionary
{
	self = [super init];
	if (self) {
		if (aDictionary) {
			
			if (![aDictionary isKindOfClass:[NSDictionary class]]) {
				self = nil;
				return nil;
			}
			
			dict = [NSMutableDictionary dictionaryWithDictionary:aDictionary];
		} else {
			dict = [NSMutableDictionary dictionaryWithCapacity:3];
		}
	}
	return self;
}

/*
 
 - TLSSecurityRequested
 
 */
- (BOOL)TLSSecurityRequested
{
	NSString *security = [self objectForKey:MGSNetMessageNegotiateKeySecurity];
	return [security isEqualToString:MGSNetMessageNegotiateSecurityTLS];
}


/*
 
 - objectForKey
 
 */
- (id)objectForKey:(id)key
{
	return [dict objectForKey:key];
}

/*
 
 - setObject:forKey:
 
 */
- (void)setObject:(id)object forKey:(id)key
{
	[dict setObject:object forKey:key];
}

/*
 
 - setRequireAuthentication:
 
 */
/*
- (void)setRequireAuthentication:(BOOL)aBool
{
	[self setObject:[NSNumber numberWithBool:aBool] forKey:MGSNetMessageNegotiateKeyAuthentication];
}
*/
/*
 
 - setSecurityType:
 
 */
- (void)setSecurityType:(NSString *)aString
{
	[self setObject:aString forKey:MGSNetMessageNegotiateKeySecurity];
}

/*
 
 - dictionary
 
 */
- (NSDictionary *)dictionary
{
	return [NSDictionary dictionaryWithDictionary:dict];
}

#pragma mark -
#pragma mark NSCopying

/*
 
 - copyWithZone:

 */
- (id)copyWithZone:(NSZone *)zone
{
	 #pragma unused(zone)
	
	MGSNetNegotiator *copy = [[[self class] alloc] initWithDictionary:[self dictionary]];
	
	return copy;
}
@end
