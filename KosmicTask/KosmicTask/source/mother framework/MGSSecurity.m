//
//  MGSSecurity.m
//  Mother
//
//  Created by Jonathan on 27/03/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSSecurity.h"

#include <CoreFoundation/CoreFoundation.h>
#include <Security/Security.h>
#include <CoreServices/CoreServices.h>

#define SSL_SUBJECT_FORMAT @"/C=GB/ST=Northern Ireland/L=Rathlin/O=Mugginsoft LLP/OU=Development/CN=%@/emailAddress=contact@mugginsoft.com"
#define SSL_COMMON_NAME @"Mugginsoft KosmicTask"

static BOOL useDefaultIdentity = NO; 

@interface MGSSecurity()
+ (SecIdentityRef)SSLIdentityCopy;
+ (SecIdentityRef)findOrCreateSelfSignedIdentityInKeychain:(SecKeychainRef)keychain;
+ (void)addSelfSignedCertToKeychain:(SecKeychainRef)keychain;
+ (SecCertificateRef)getSelfSignedCertificateInKeychain:(SecKeychainRef)keychain;
+ (SecIdentityRef)SSLIdentityCopy;
@end

@implementation MGSSecurity 

/*
 
 + useDefaultIdentity
 
 */
+ (BOOL)useDefaultIdentity
{
	return useDefaultIdentity;
}

/*
 
 + useDefaultIdentity
 
 */
+ (void)setUseDefaultIdentity:(BOOL)aBool
{
	useDefaultIdentity = aBool;
}

/*
 
 + sslCertificatesArray
 
 */
+ (CFArrayRef)sslCertificatesArray {
	static CFArrayRef ca = NULL;

	if(!ca) {
		
		// Use the system identity		
		SecIdentityRef identity = [self SSLIdentityCopy];
		
		if (identity) {
			ca = CFArrayCreate(NULL, (const void **)&identity, 1, NULL);
		} 
	}
	
	return ca;
}
/*
 
 get server socket SSL identity
 
 */
+ (SecIdentityRef)SSLIdentityCopy
{
	OSStatus err = noErr;
	SecIdentityRef mySSLIdentity = NULL;
	
	if ([self useDefaultIdentity]) {
		
		/*

		 NOTE:
		 
		 This tends to fail with 
		 
		 code -9845 the operation couldn't be completed
		 
		 when the identity is used to secure an SSL connection.
		 
		 */
		CFStringRef actualDomain = NULL;
		
		// also see SecIdentityCopySystemIdentity which can use the system identity.
		// this approach is detailed in Graham J Lees - Professional Cocoa Application Security.
		err = SecIdentityCopySystemIdentity(kSecIdentityDomainDefault, &mySSLIdentity, &actualDomain);
		if (err != noErr) {
			MLogInfo(@"Cannot obtain system identity. Error = %n", err);
		}
		MLogDebug(@"Actual domain for default identity = %@", actualDomain);
		CFRelease(actualDomain);
	} else {
		//==================================
		// set up server side SSL 
		// code from David Riggle at BusyMac
		//==================================
		SecKeychainRef keychainRef = nil;

		
		// get SSL identity
		err = SecKeychainCopyDefault(&keychainRef);
		if (err != noErr) return nil;
		mySSLIdentity = [MGSSecurity findOrCreateSelfSignedIdentityInKeychain:keychainRef];
		
		CFRelease(keychainRef);
	}
	
	return mySSLIdentity;
}

/*
 
 find or create self signed identity in keychain
 
 */
+ (SecIdentityRef)findOrCreateSelfSignedIdentityInKeychain:(SecKeychainRef)keychain
{
	BOOL createdIdentity = NO;
	SecIdentitySearchRef searchRef = nil;
	OSStatus err;
	
	err = SecIdentitySearchCreate(keychain, CSSM_KEYUSE_DECRYPT, &searchRef);
	if (err != noErr) {
		MLogInfo(@"Cannot search keychain. Error = %n", err);
		return nil;
	}
	
	for (;;) {
		SecIdentityRef mySSLIdentity = nil;
		err = SecIdentitySearchCopyNext(searchRef, &mySSLIdentity);
		if (err == errSecItemNotFound && !createdIdentity) {
			MLog(RELEASELOG, @"SSL identity not found, creating one");
			// identity not found; create our own
			[MGSSecurity addSelfSignedCertToKeychain:keychain];
			// restart search
			CFRelease(searchRef);
			err = SecIdentitySearchCreate(keychain, CSSM_KEYUSE_DECRYPT, &searchRef);
			if (err != noErr) break;
			createdIdentity = YES;
			continue;
		}
		if (err != noErr) break;
		
		// an identity found; see if it is ours
		SecCertificateRef certificateRef = nil;
		err = SecIdentityCopyCertificate(mySSLIdentity, &certificateRef);
		if (err == noErr) {
			CFStringRef commonName = nil;
			err = SecCertificateCopyCommonName(certificateRef, &commonName);
			if (err == noErr) {
				MLog(DEBUGLOG,  @"SSL common name = %@", commonName);
				if ([(NSString *)commonName isEqual:SSL_COMMON_NAME]) {
					MLog(DEBUGLOG, @"SSL identity found");
					// found it
					CFRelease(commonName);
					CFRelease(certificateRef);
					CFRelease(searchRef);
					return mySSLIdentity;
				}
			}
			if (commonName != nil) CFRelease(commonName);
		}
		
		// clean up
		if (certificateRef != nil) CFRelease(certificateRef);
		if (mySSLIdentity != nil) CFRelease(mySSLIdentity);
	}
	
	// clean up
	if (searchRef != nil) CFRelease(searchRef);
	return nil;
}

/*
 
 get self signed certificate in keychain
 
 */
+ (SecCertificateRef)getSelfSignedCertificateInKeychain:(SecKeychainRef)keychain
{
	BOOL createdIdentity = NO;
	SecIdentitySearchRef searchRef = nil;
	OSStatus err;
	
	err = SecIdentitySearchCreate(keychain, CSSM_KEYUSE_DECRYPT, &searchRef);
	if (err != noErr) {
		NSLog(@"Cannot obtain system identity. Error = %n", err);
		return nil;
	}
	for (;;) {
		SecIdentityRef mySSLIdentity = nil;
		err = SecIdentitySearchCopyNext(searchRef, &mySSLIdentity);
		if (err == errSecItemNotFound && !createdIdentity) {
			return nil;
		}
		if (err != noErr) return nil;
		
		// an identity found; see if it is ours
		SecCertificateRef certificateRef = nil;
		err = SecIdentityCopyCertificate(mySSLIdentity, &certificateRef);
		if (err == noErr) {
			CFStringRef commonName = nil;
			err = SecCertificateCopyCommonName(certificateRef, &commonName);
			if (err == noErr) {
				MLog(DEBUGLOG,  @"SSL common name = %@", commonName);
				if ([(NSString *)commonName isEqual:SSL_COMMON_NAME]) {
					MLog(DEBUGLOG, @"SSL certificate found");
					// found it
					CFRelease(commonName);
					CFRelease(mySSLIdentity);
					CFRelease(searchRef);
					return certificateRef;
				}
			}
			if (commonName != nil) CFRelease(commonName);
		}
		
		// clean up
		if (certificateRef != nil) CFRelease(certificateRef);
		if (mySSLIdentity != nil) CFRelease(mySSLIdentity);
	}
	
	// clean up
	if (searchRef != nil) CFRelease(searchRef);
	return nil;
}

/*
 
 add self signed cert to keychain
 
 */
+ (void)addSelfSignedCertToKeychain:(SecKeychainRef)keychain
{
	// create a path to a temp file
	NSString *tmpPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"tmpCert.pem"];
	if (tmpPath == nil) return;
	
	NSString *subject = [NSString stringWithFormat:SSL_SUBJECT_FORMAT, SSL_COMMON_NAME];
	
	@try {
		/*
		 also see:
		 
		 man security (access keychains and do all the securtiy framework can do)
		 man certtool (generate certificates)
		 
		 */
		
		// launch openssl to create the certificate
		// see http://www.openssl.org/docs/apps/req.html# for parameter documentation or
		// http://www.modssl.org/docs/2.8/ssl_intro.html
		NSTask *openSSLProcess = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/openssl"
										arguments:[NSArray arrayWithObjects:
										@"req", @"-x509", @"-nodes", @"-days", @"3650",
										@"-subj", subject,
										@"-newkey", @"rsa:1024", @"-keyout", tmpPath, @"-out", tmpPath,
										// @"-passin", @"pass:passphrase", nil]];
										nil]];
		
		// need to busy wait for subtask to finish, because we don't want to go into another run loop & get more AsyncSocket call-backs
		do {
			[NSThread sleepForTimeInterval:0.1];
		} while ([openSSLProcess isRunning]);
		
		if ([openSSLProcess terminationStatus] != 0) {
			MLog(DEBUGLOG, @"openSSL task failed.");
			return;
		}
	} @catch (NSException *e) {
		MLog(DEBUGLOG, @"exception adding certificate: %@", e);
		[e raise];
		return;
	}
	
	// add certificate to keychain
	SecExternalFormat format = kSecFormatPEMSequence;
	SecExternalItemType type = kSecItemTypeAggregate;
	SecKeyImportExportParameters params;
	memset(&params, 0, sizeof(params));
	
	params.version = SEC_KEY_IMPORT_EXPORT_PARAMS_VERSION;
	// params.passphrase = CFSTR("passphrase");
	// params.flags = kSecKeySecurePassphrase;
	params.keyUsage = CSSM_KEYUSE_DECRYPT;
	params.keyAttributes = CSSM_KEYATTR_EXTRACTABLE | CSSM_KEYATTR_PERMANENT;
	
	OSStatus err = SecKeychainItemImport(
										 (CFDataRef) [NSData dataWithContentsOfFile:tmpPath],
										 (CFStringRef) tmpPath,
										 &format,
										 &type,
										 0,
										 &params,
										 keychain,
										 NULL);
	
	if (err != noErr) {
		MLog(RELEASELOG, @"SecKeychainItemImport returned %d.", err);
	}
	
	[[NSFileManager defaultManager] removeItemAtPath:tmpPath error:NULL];
}

/*
 
 show certficate
 
 */
+ (void)showCertificate
{
	SecCertificateRef mySSLCert = nil;
	OSStatus err;

	if ([self useDefaultIdentity]) {
	
		SecIdentityRef secIdRef;
		err = SecIdentityCopySystemIdentity(kSecIdentityDomainDefault, &secIdRef, NULL);
		if (err != noErr) {
			MLog(RELEASELOG, @"Cannot obtain system identity. Error = %n", err);
			return;
		}

		err = SecIdentityCopyCertificate(secIdRef, &mySSLCert);
		if (err != noErr) {
			MLog(RELEASELOG, @"Cannot obtain system identity certficate. Error = %n", err);
			return;
		}
		
		
	} else {
		SecKeychainRef keychainRef = nil;

		// get SSL identity
		err = SecKeychainCopyDefault(&keychainRef);
		if (err != noErr) {
			MLog(RELEASELOG, @"Cannot get keychain ref");
			return;
		}
		
		mySSLCert = [MGSSecurity getSelfSignedCertificateInKeychain:keychainRef];
		if (mySSLCert == NULL) {
			MLog(RELEASELOG, @"SSL certficate not found");
			return;
		}
	}


	
	// show cert in modal panel
	SFCertificatePanel *certPanel = [SFCertificatePanel sharedCertificatePanel];
	[certPanel runModalForCertificates:[NSArray arrayWithObject:(id)mySSLCert] showGroup:NO];
	
	CFRelease(mySSLCert);
	return;
}
@end
