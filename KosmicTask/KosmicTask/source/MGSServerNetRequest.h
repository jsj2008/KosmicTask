//
//  MGSServerNetRequest.h
//  KosmicTask
//
//  Created by Jonathan on 08/10/2012.
//
//

#import <Cocoa/Cocoa.h>
#import "MGSNetRequest.h"

@interface MGSServerNetRequest : MGSNetRequest

+ (id) requestWithConnectedSocket:(MGSNetSocket *)netSocket;
- (MGSServerNetRequest *)initWithConnectedSocket:(MGSNetSocket *)socket;
- (void)sendResponseOnSocket;
- (void)sendResponseChunkOnSocket:(NSData *)data;
- (BOOL)authenticate;
- (BOOL)authenticateWithAutoResponseOnFailure:(BOOL)autoResponse;

@end
