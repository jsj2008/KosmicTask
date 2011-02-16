//
//  MGSInternetSharingServer.m
//  Mother
//
//  Created by Jonathan on 08/09/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSInternetSharingServer.h"
#import "MGSPreferences.h"
#import "MGSDistributedNotifications.h"
#import "NSDictionary_Mugginsoft.h"

@implementation MGSInternetSharingServer

/*
 
 init
 
 */
- (id)init
{
	return nil;
}

/*
 
 init with external port and listening port
 
 designated initialiser
 
 */
- (id)initWithExternalPort:(NSInteger)externalPort listeningPort:(NSInteger)listeningPort
{
	if ((self = [super init])) {
		
		self.listeningPort = listeningPort;
		
		// register to receive internet sharing request notification
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(request:) 
																name:MGSDistNoteInternetSharingRequest object:self.noteObjectString];
	
		// read preferences
		MGSPreferences *preferences = [MGSPreferences standardUserDefaults];
		
		if ([preferences objectForKey:MGSExternalPortNumber]) {
			self.externalPort = [preferences integerForKey:MGSExternalPortNumber];
		} else {
			self.externalPort = externalPort; 
		}
		
		self.allowInternetAccess = [preferences boolForKey:MGSAllowInternetAccess];
		self.enableInternetAccessAtLogin = [preferences boolForKey:MGSEnableInternetAccessAtLogin];
		
		if (self.enableInternetAccessAtLogin) {
			
			// start mapping
			[self startPortMapping];
		}
		
		[self postStatusNotification];
	}
	
	return self;
}

/*
 
 request notification
 
 the sender of this winotification will be waiting for a response
 
 */
- (void)request:(NSNotification *)note
{
	NSDictionary *userInfo = [note userInfo];
	
	// get the request id
	MGSInternetSharingRequestID requestID = [[userInfo objectForKey:MGSInternetSharingKeyRequest] integerValue];
	
	switch (requestID) {
			
		// status request
		case kMGSInternetSharingRequestStatus:
			[self postStatusNotification];
			break;
		
		// internet access request
		case kMGSInternetSharingRequestInternetAccess:
			self.allowInternetAccess = [[userInfo objectForKey:MGSAllowInternetAccess] boolValue];
			break;
			
		// start mapping request
		case kMGSInternetSharingRequestStartMapping:;
			NSInteger externalPort = [[userInfo objectForKey:MGSExternalPortNumber] integerValue];
			
			// if a new port requested then remap
			if (externalPort != self.externalPort) {
				self.externalPort = externalPort;
				[self remapPortMapping];
			}
			[self startPortMapping];
			break;

		// stop mapping request
		case kMGSInternetSharingRequestStopMapping:
			[self stopPortMapping];
			break;
		
		// start at login request
		case kMGSInternetSharingRequestStartAtLogin:
			self.enableInternetAccessAtLogin = [[userInfo objectForKey:MGSEnableInternetAccessAtLogin] boolValue];
			[self postStatusNotification];
			break;
		
		// remap the port	
		/*
		case kMGSInternetSharingRequestStartRemapPort:
			self.externalPort = [[userInfo objectForKey:MGSExternalPortNumber] integerValue];
			[self remapPortMapping];
			break;
		*/
			
		// unrecognised
		default:
			MLog(RELEASELOG, @"unrecognised internet sharing request id: %i", requestID);
			[self postStatusNotification];
			break;
	}
	
}

/*
 
 set allow internet access
 
 */
- (void)setAllowInternetAccess:(BOOL)value
{
	[super setAllowInternetAccess:value];

	if (value) {
		
		// initialise the mapper
		[self initialisePortMapping];
		[self postStatusNotification];
	} else {
		[self stopPortMapping];
		self.enableInternetAccessAtLogin = NO;
	}
}

/*
 
 set enable internet access at login
 
 */
-(void)setEnableInternetAccessAtLogin:(BOOL)value
{
	[super setEnableInternetAccessAtLogin:value];	
}

/*
 
 post status notification
 
 */
- (void)postStatusNotification
{
	// send out a status distributed notification
	[self postDistributedResponseNotificationWithDict:[self statusDictionary]];
}

/*
 
 initialise port mapping
 
 */
- (void)initialisePortMapping
{
	NSAssert(self.listeningPort != 0, @"Cannot start port mapper as listening port not defined"); 
	
	// lazy allocation
	if (!_portMapper) {
		
		// validate external port
		if (self.externalPort == 0) {
			return;
		}
		
		// initialise the mapper
		_portMapper = [[MGSPortMapper alloc] initWithExternalPort:self.externalPort listeningPort:self.listeningPort];
		_portMapper.delegate = self;
		
	}
	
}

/*
 
 start port mapping
 
 */
- (void)startPortMapping
{
	// make sure that we have initialised
	[self initialisePortMapping];
	
	// start mapping if port mot mapped
	if ([self mappingStatus] == kMGSInternetSharingPortNotMapped) {
		[_portMapper startMapping];
	} else {
		
		// our client will be waiting for a notification.
		[self postStatusNotification];
	}
}

/*
 
 remap port mapping
 
 */
- (void)remapPortMapping
{
	if (_portMapper) {
		if (self.externalPort > 0) {
			[_portMapper remapWithExternalPort:self.externalPort listeningPort:self.listeningPort];
		}
	} else {
		[self startPortMapping];
	}
}

/*
 
 stop port mapping
 
 */
- (void)stopPortMapping
{
	// start mapping if port mot mapped
	if ([self mappingStatus] == kMGSInternetSharingPortMapped) {
		[_portMapper stopMapping];
	} else {
		
		// our client will be waiting for a notification.
		[self postStatusNotification];
	}
}


/*
 
 dispose 
 
 call on termination
 
 */
- (void)dispose
{
	// stop the port mapper permanently
	[_portMapper dispose];
	
	// remove observers
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
	
	// write out preferences
	[[MGSPreferences standardUserDefaults] setObject:[NSNumber numberWithBool:self.enableInternetAccessAtLogin] forKey:MGSEnableInternetAccessAtLogin];
	[[MGSPreferences standardUserDefaults] setObject:[NSNumber numberWithBool:self.allowInternetAccess] forKey:MGSAllowInternetAccess];
	[[MGSPreferences standardUserDefaults] setObject:[NSNumber numberWithInteger:self.externalPort] forKey:MGSExternalPortNumber];
	[[MGSPreferences standardUserDefaults] synchronize];
	
}


/*
 
 status dictionary
 
 */
- (NSDictionary *)statusDictionary
{
	NSDictionary *dict =  [NSDictionary dictionaryWithObjectsAndKeys: 
			[NSNumber numberWithInteger:kMGSInternetSharingRequestStatus], MGSInternetSharingKeyRequest,
			[NSNumber numberWithInteger:[self mappingStatus]], MGSInternetSharingKeyMappingStatus,
			[self IPAddressString], MGSInternetSharingKeyIPAddress,
			[self gatewayName], MGSInternetSharingKeyGatewayName,
			[NSNumber numberWithInteger:self.externalPort], MGSExternalPortNumber,
			[NSNumber numberWithBool:self.allowInternetAccess], MGSAllowInternetAccess,
			[NSNumber numberWithBool:self.enableInternetAccessAtLogin], MGSEnableInternetAccessAtLogin,
			nil];
	
	MLog(DEBUGLOG, @"Internet sharing response dict sent by server: %@", [dict propertyListStringValue]);
	
	return dict;
}

/*
 
 ip address string
 
 */
- (NSString *)IPAddressString
{
	NSString *address = nil;
	
	if (_portMapper) {
		address = [_portMapper externalIPAddress];
	}
	
	if (!address) {
		address = NSLocalizedString(@"not available", @"Internet sharing IP address not available");
	}
	
	return address;
}


/*
 
 gateway name
 
 */
- (NSString *)gatewayName
{
	NSString *name = nil;
	
	if (_portMapper) {
		name = [_portMapper gatewayName];
	}
	
	if (!name) {
		name = NSLocalizedString(@"not available", @"Internet sharing gateway name not available");
	}
	
	return name;
}


/*
 
 mapping status
 
 */
- (MGSInternetSharingMappingStatus)mappingStatus
{
	if (_portMapper) {
		switch ([_portMapper mappingStatus])
		{
				
			case TCMPortMappingStatusTrying:
				return kMGSInternetSharingPortTryingToMap;
				break;
				
			case TCMPortMappingStatusMapped:
				return kMGSInternetSharingPortMapped;
				break;

			case TCMPortMappingStatusUnmapped:
			default:
				return kMGSInternetSharingPortNotMapped;
				break;
		}
	} else {
		return kMGSInternetSharingPortNotMapped;
	}
}

#pragma mark port mapper delegate methods

/*
 
 port mapper did start work
 
 */
- (void)portMapperDidStartWork
{
	//[self postStatusNotification];
}

/*
 
 port mapper did finish work
 
 */
- (void)portMapperDidFinishWork
{
	NSInteger externalPort = [_portMapper externalPort];
	
	// our allocated port may differ from our requested port if the requested port was already mapped
	if (self.externalPort != externalPort && externalPort != 0) {
		self.externalPort = externalPort;
	}
	
	[self postStatusNotification];
}
@end
