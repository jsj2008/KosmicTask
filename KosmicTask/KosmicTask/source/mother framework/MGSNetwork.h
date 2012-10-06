//
//  MGSNetwork.h
//  KosmicTask
//
//  Created by Jonathan on 06/10/2012.
//
//

#import <Foundation/Foundation.h>
#import <arpa/inet.h> // For AF_INET, etc.

@interface MGSNetwork : NSObject {
    
}
+ (NSArray *)localHostAddresses;
+ (NSString *)sockaddrAddress:(struct sockaddr *)sa;
+ (NSSet *)localHostAddressesSet;
@end
