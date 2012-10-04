//
//  NSNetService+Mugginsoft.m
//  KosmicTask
//
//  Created by Jonathan on 04/10/2012.
//
//
#import "MGSMother.h"
#import "NSNetService+Mugginsoft.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import "NSString_Mugginsoft.h"

@implementation NSNetService (Mugginsoft)

/*
 
 - mgs_addressStrings
 
 */
- (NSSet *)mgs_addressStrings
{
    NSMutableSet *bonjourAddresses = [NSMutableSet setWithCapacity:[[self addresses] count]];
    [bonjourAddresses unionSet:[self mgs_IPv4AddressStrings]];
    [bonjourAddresses unionSet:[self mgs_IPv6AddressStrings]];
    return bonjourAddresses;
}
  
/*
 
 - mgs_IPv4AddressStrings
 
 */
- (NSSet *)mgs_IPv4AddressStrings
{
    // may be called with zero addresses when service is removed
    NSArray *addresses = [self addresses];
    NSMutableSet *IPv4Addresses = [NSMutableSet setWithCapacity:[addresses count]];
    
    // http://deusty.blogspot.co.uk/2008/06/bonjour-and-ipv6.html
    for(NSUInteger i = 0; i < [addresses count]; i++)
    {
        struct sockaddr *sa = (struct sockaddr *)[[addresses objectAtIndex:i] bytes];
        
        if(sa->sa_family == AF_INET)
        {
            NSString *address = [NSString mgs_StringWithSockAddrData:[addresses objectAtIndex:i]];
            if (address) {
                [IPv4Addresses addObject:address];
            }
        }
    }
    
    return IPv4Addresses;
}

/*
 
 - mgs_IPv6AddressStrings
 
 */
- (NSSet *)mgs_IPv6AddressStrings
{
    // may be called with zero addresses when service is removed
    NSArray *addresses = [self addresses];
    NSMutableSet *IPv6Addresses = [NSMutableSet setWithCapacity:[addresses count]];
    
    // http://deusty.blogspot.co.uk/2008/06/bonjour-and-ipv6.html
    for (NSUInteger i = 0; i < [addresses count]; i++)
    {
        struct sockaddr *sa = (struct sockaddr *)[[addresses objectAtIndex:i] bytes];
        
        if(sa->sa_family == AF_INET6)
        {
            NSString *address = [NSString mgs_StringWithSockAddrData:[addresses objectAtIndex:i]];
            if (address) {
                [IPv6Addresses addObject:address];
            }
        }
    }
    
    return IPv6Addresses;
}

@end
