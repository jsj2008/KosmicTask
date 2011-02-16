//
//  main.m
//  mother
//
//  Created by Jonathan Mitchell on 31/10/2007.
//  Copyright Mugginsoft 2007. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MGSMother.h"
#import "MGSMotherServer.h"
#import "MGSConnectionMonitor.h"

int main(int argc, char *argv[])
{
	//NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];


	// connection using specified port
	// set DO receive port	
	NSSocketPort *receivePort;
	@try {
		receivePort = [[NSSocketPort alloc] initWithTCPPort:8081];
	}
	@catch (NSException *e) {
		NSLog(@"unable to get port 8081");
		exit(-1);
	}

	MGSMotherServer *motherServer = [[MGSMotherServer alloc] init];

	// set up the connection monitor notifications
	MGSConnectionMonitor *connectionMonitor = [[MGSConnectionMonitor alloc] init];
	NSNotificationCenter *notificationCentre = [NSNotificationCenter defaultCenter];
	
	// connection initialized - sent when connectionn created
	[notificationCentre addObserver:connectionMonitor 
						   selector:@selector(connectionDidInitialize:)
							   name:NSConnectionDidInitializeNotification
							 object:nil];

	NSConnection *connection = [NSConnection connectionWithReceivePort:receivePort sendPort:nil];
	
	// connection died
	/*[notificationCentre addObserver:connectionMonitor 
						   selector:@selector(connectionDidDie:)
							   name:NSConnectionDidDieNotification
							 object:connection];
	*/
	
	[connection setDelegate:connectionMonitor];
	[connection setRootObject:motherServer];
	
 //[receivePort release];	// retained by the connection

	// vend the mother server instance via default connection object
	// see Anguish page 868
	/* from 10.5 release notes
	 
	 	New NSConnection API
	 + (id)serviceConnectionWithName:(NSString *)name rootObject:(id)root usingNameServer:(NSPortNameServer *)server;
	 + (id)serviceConnectionWithName:(NSString *)name rootObject:(id)root;
	 These new methods are used to create a new NSConnection by an autolaunched service process, 
	 for the service(s) they are providing. The connection is configured with the given root object.
	 -registerName: should not be used with such an NSConnection, and -setRootObject: is unnecessary. 
	 This also checks the service in with launchd
	 
	 */
	/* need to specify an NSSocketPort to enable DO to another machine
	connection = [NSConnection defaultConnection];
	[connection setDelegate:connectionMonitor];
	[connection setRootObject:motherServer];
	if ([connection registerName:MGSMotherServerName] == NO) {
		NSLog(@"unable to register server name %@", MGSMotherServerName);
		exit(-1);
	}
	*/
	// publish service via Bonjour
	// note that the service name must be different for each server
	// on the network otherwise an NSNetServicesCollisionError will occur
	NSString *serviceName = [[NSHost currentHost] name];
	NSNetService *netService = [[NSNetService alloc] initWithDomain:@"" type:@"_mgsmother._tcp." name:serviceName port:8081];
	[netService setDelegate:connectionMonitor];
	[netService publish];
	
	// stert the runloop
	NSRunLoop *runloop = [NSRunLoop currentRunLoop];
	[runloop run];

	
    return 0;
}