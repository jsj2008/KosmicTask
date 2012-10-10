//
//  MGSError.h
//  Mother
//
//  Created by Jonathan on 03/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

//#import <Cocoa/Cocoa.h>
#import "NSError_Mugginsoft.h"

@class MGSErrorWindowController;

// NSError domains
extern NSString *MGSErrorDomainMotherServer;
extern NSString *MGSErrorDomainMotherClient;
extern NSString *MGSErrorDomainMotherFramework;
extern NSString *MGSErrorDomainMotherNetwork;
extern NSString *MGSErrorDomainMotherScriptTask;

// error codes
// these are defines as const int is not const enough for a switch case label!

// network errors
#define MGSErrorCodeSocketError 1
#define MGSErrorCodeSocketCanceledError 2			// onSocketWillConnect: returned NO.
#define MGSErrorCodeSocketReadTimeoutError 3
#define MGSErrorCodeSocketWriteTimeoutError 4
#define MGSErrorCodeSocketDisconnectError 5
#define MGSErrorCodeSocketSSLPropertyError 6
#define MGSErrorCodeSocketConnectError 7

// exceptions
#define MGSErrorCodeTaskLaunchException 100
#define MGSErrorCodeClientException 101
#define MGSErrorCodeServerException 102
#define MGSErrorCodeServerUnknown 103

// request errors
#define MGSErrorCodeParseRequestScript 1001
#define MGSErrorCodeParseRequestMessage 1002
#define MGSErrorCodeSendRequestMessage 1003
#define MGSErrorCodeProcessMessage 1004
#define MGSErrorCodeAuthenticationFailure 1005
#define MGSErrorCodeInvalidCommandReply 1006
#define MGSErrorCodeParseRequestPreferences 1007
#define MGSErrorCodeAttachment 1008
#define MGSErrorCodeDefaultRequestError 1009
#define MGSErrorCodeRequestPreferenceError 1010
#define MGSErrorCodeSearchError 1011
#define MGSErrorCodeTrialRestrictionImposed 1012
#define MGSErrorCodeLicenceRestrictionImposed 1013
#define MGSErrorCodeCompiledScriptSourceRTFMissing 1014
#define MGSErrorCodeCompiledScriptDataMissing 1015
#define MGSErrorCodeInvalidScriptRepresentation 1016
#define MGSErrorCodeSecureConnectionRequired 1017
#define MGSErrorCodeBadRequestFormat 1018
#define MGSErrorCodeRequestedSecurityNotGranted 1019
#define MGSErrorCodeRequestWriteConnectionTimeout 1020
#define MGSErrorCodeRequestWriteTimeout 1021
#define MGSErrorCodeRequestTimeout 1022

// script errors
#define MGSErrorCodeScriptRunner 2000
#define MGSErrorCodeScriptBuild 2001
#define MGSErrorCodeScriptExecute 2002
#define MGSErrorCodeGetCompiledScriptSource 2003
#define MGSErrorCodeSaveScript 2004
#define MGSErrorCodeGetScript 2005
#define MGSErrorCodeLoadScriptFromFile 2006

// plugin errors
#define MGSErrorCodePlugin 3000
#define MGSErrorCodeExportPlugin 3001
#define MGSErrorCodeSendPlugin 3002
#define MGSErrorCodeParameterPlugin 3003

// licensing errors
#define MGSLicenceCopyError 4000
#define MGSLicenceRemovalError 4001

// message errors
#define MGSErrorCodeMessageBadData 5000

// application errors
#define MGSErrorCodeCannotConnectToService 6000

// validation errors
#define MGSErrorCodeTaskNameNotDefined 7000
#define MGSErrorCodeTaskGroupNotDefined 7001

@interface MGSError : NSError {
	NSDate *_date;
	NSUInteger flags; 
    NSString *_machineName;
}

// class messages
+ (id)errorWithDictionary:(NSDictionary *)dict log:(BOOL)logIt;
+ (id)errorWithDictionary:(NSDictionary *)dict;
+ (void)setWindowController:(MGSErrorWindowController *)controller;
+ (id)clientCode:(NSInteger)code reason:(NSString *)message log:(BOOL)logIt;

// framework
+ (id)frameworkCode:(NSInteger)code;
+ (id)frameworkCode:(NSInteger)code reason:(NSString *)message;
+ (id)frameworkCode:(NSInteger)code userInfo:(NSDictionary *)userDict;

// server
+ (id)serverCode:(NSInteger)code;
+ (id)serverCode:(NSInteger)code userInfo:(NSDictionary *)userDict;
+ (id)serverCode:(NSInteger)code reason:(NSString *)message;

// client
+ (id)clientCode:(NSInteger)code;
+ (id)clientCode:(NSInteger)code reason:(NSString *)message;
+ (id)clientCode:(NSInteger)code userInfo:(NSDictionary *)userDict;
+ (id)clientCode:(NSInteger)code reason:(NSString *)message log:(BOOL)logIt;

+ (NSString *)descriptionFromCode:(NSInteger)code;
+ (id)domain:(NSString *)domain code:(NSInteger)code;
+ (id)domain:(NSString *)domain code:(NSInteger)code userInfo:(NSDictionary *)userDict;
+ (id)domain:(NSString *)domain code:(NSInteger)code userInfo:(NSDictionary *)userDict log:(BOOL)logIt;
+ (id)domain:(NSString *)domain code:(NSInteger)code reason:(NSString *)message log:(BOOL)logIt;


+ (NSMutableDictionary *)userInfoFromAppleScriptErrorDict:(NSDictionary *)errorDict;

// instance messages
- (NSDictionary *)dictionary;
- (NSString *)stringValue;
- (NSDictionary *)resultDictionary;
- (NSString *)localizedFailureReasonPreview;
- (NSString *)stringValuePreview;
- (void)logToController;
- (void)logToConsole;
- (void)log;

@property (assign) NSDate *date;
@property NSUInteger flags; 
@property (assign)NSString *machineName;
@end
