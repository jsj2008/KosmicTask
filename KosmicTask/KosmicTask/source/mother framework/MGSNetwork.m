//
//  MGSNetwork.m
//  KosmicTask
//
//  Created by Jonathan on 06/10/2012.
//
//

#import "MGSNetwork.h"

#import <ifaddrs.h> // For getifaddrs()
#import <net/if.h> // For IFF_LOOPBACK

@implementation MGSNetwork

/*
 
 + localHostAddresses
 
 */
+ (NSArray *)localHostAddresses
{
    NSMutableArray *localHostAddresses = [NSMutableArray arrayWithCapacity:10];

    struct ifaddrs *addresses = NULL;
    struct ifaddrs *cursor = NULL;
    struct sockaddr *sa = NULL;
    
    // get
    if (getifaddrs(&addresses) != 0) {
        NSLog(@"Could not load network interface data.");
        return localHostAddresses;
    }
    
    cursor = addresses;
    while (cursor != NULL) {
        
        if (cursor->ifa_addr == NULL) continue; // this happens
        //if ((cursor->ifa_flags & IFF_UP) == 0) continue;    // IF must be UP
        
        // get socket address
        sa = cursor->ifa_addr;
        NSString *name = [self sockaddrAddress:sa];
        if (name) {
            [localHostAddresses addObject:name];

#ifdef MUGGINSOFT_DEBUG
            //NSLog(@"Localhost address found: %@", name);
#endif
        }
        cursor = cursor -> ifa_next;
    }
    
    freeifaddrs(addresses);

#ifdef MUGGINSOFT_DEBUG
    NSLog(@"Localhost addresses found: %@", localHostAddresses);
#endif

    return localHostAddresses;
}
/*
 
 - localHostAddressesSet
 
 */
+ (NSSet *)localHostAddressesSet
{
    // get host addresses
    NSArray *addresses = [self localHostAddresses];
    
    // make set
    NSMutableSet *theSet = [NSMutableSet setWithArray:addresses];
    
    return theSet;
}
/*
 
 - sockaddrAddress:
 
 */
+ (NSString *)sockaddrAddress:(struct sockaddr *)sa
{
    char addr[256];
    NSString *address = nil;
    BOOL addressIsValid = NO;
    
    if(sa->sa_family == AF_INET6) {
        struct sockaddr_in6 *sin6 = (struct sockaddr_in6 *)sa;
        
        if(inet_ntop(AF_INET6, &sin6->sin6_addr, addr, sizeof(addr)))
        {
            addressIsValid = YES;
        }
    } else if(sa->sa_family == AF_INET) {
        struct sockaddr_in *sin = (struct sockaddr_in *)sa;
        
        if(inet_ntop(AF_INET, &sin->sin_addr, addr, sizeof(addr)))
        {
            addressIsValid = YES;
        }
    }
    
    if (addressIsValid) {
        address = [NSString stringWithCString:addr encoding:NSASCIIStringEncoding];
    }
    
    return address;

}
@end
