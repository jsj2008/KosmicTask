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
static NSDictionary *identityOptions = nil;

@interface MGSSecurity()
+ (SecIdentityRef)SSLIdentityCopy;
+ (SecIdentityRef)findOrCreateSelfSignedIdentityInKeychain:(SecKeychainRef)keychain;
+ (void)addSelfSignedCertToKeychain:(SecKeychainRef)keychain;
+ (SecCertificateRef)getSelfSignedCertificateInKeychain:(SecKeychainRef)keychain;
+ (NSString *)secErrorString:(OSStatus)err;
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
 + setIdentityOptions
 */
+ (void)setIdentityOptions:(NSDictionary *)options
{
    identityOptions = options;
           
    //SecKeychainItemRef privateKey = NULL;
    //SecKeychainSearchRef searchRef = NULL;
    
    //Set up the attribute vector (each attribute consists
    // of {tag, length, pointer}):
    /*SecKeychainAttribute attrs[] = {
     { kSecLabelItemAttr, strlen(itemLabelUTF8), (char *)itemLabelUTF8 },
     { kSecAccountItemAttr, strlen(accountUTF8), (char *)accountUTF8 },
     { kSecServerItemAttr, strlen(serverUTF8), (char *)serverUTF8 },
     { kSecPortItemAttr, sizeof(int), (int *)&port },
     { kSecProtocolItemAttr, sizeof(SecProtocolType),
     (SecProtocolType *)&protocol },
     { kSecPathItemAttr, strlen(pathUTF8), (char *)pathUTF8 }
     };
     SecKeychainAttributeList attributes = { sizeof(attrs) / sizeof(attrs[0]),
     attrs };*/
   /* 
    SecKeychainSearchCreateFromAttributes(NULL, kSecPrivateKeyItemClass, NULL, &searchRef);
    if (err != noErr) {
        return NO;
    }

    NSMutableDictionary *query = [[NSMutableDictionary alloc] init];
    [query setObject:(id)kSecClassKey forKey:(id)kSecClass];
    [query setObject:(id)kSecMatchLimitOne forKey:(id)kSecMatchLimit];
    [query setObject:(id)kSecAttrKeyClassPrivate forKey:(id)kSecAttrKeyClass];
    [query setObject:(id)[NSArray arrayWithObject:(id)identity] forKey:(id)kSecMatchItemList];
    
    NSMutableDictionary *queryResult = nil;
    err = SecItemCopyMatching((CFDictionaryRef)query, (CFTypeRef *)queryResult);
    if (err != noErr) {
        return NO;
    }
    */
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
            
            // when used to secure an SSL connection the certficate array has to include and identity as the
            // first item
			ca = CFArrayCreate(NULL, (const void **)&identity, 1, &kCFTypeArrayCallBacks);
			CFRelease(identity);
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
		
		/*
		 
		 collector thread sometimes crashes when freeing SecKeychain object.
		 thread 0 seen to be accessing keychain at same time.
		 
		 so just keep this keychain reference around.
		 
		 */
		static __strong SecKeychainRef keychainRef = NULL;

		
		// get SSL identity
		
		/*
		 
		 Crash potential?
		 
		 http://projects.mugginsoft.net/view.php?id=1018
		 
		 */
		if (keychainRef == NULL) { 
			err = SecKeychainCopyDefault(&keychainRef);
			if (err != noErr) return nil;
		}
	
		// make it collectable but the strong ref above should prevent this.
		CFMakeCollectable(keychainRef);
		mySSLIdentity = [MGSSecurity findOrCreateSelfSignedIdentityInKeychain:keychainRef];
		
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
	
    /*
     an identity in this context is a combination of a private key and its associated certificate.
     
     see Certificate, Key, and Trust Services Programming Guide
     http://developer.apple.com/library/ios//#/library/mac/documentation/Security/Conceptual/CertKeyTrustProgGuide/01introduction/introduction.html#//apple_ref/doc/uid/TP40001358-CH203-DontLinkElementID_11
     
     */
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
		NSLog(@"Cannot obtain system identity. Error = %ld", (long)err);
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
    OSStatus err = noErr;
    
	// create a path to a temp file
	NSString *tmpPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"tmpCert.pem"];
	if (tmpPath == nil) return;
	
	NSString *subject = [NSString stringWithFormat:SSL_SUBJECT_FORMAT, SSL_COMMON_NAME];
	
	@try {
		/*
		 also see:
		 
		 man security (access keychains and do all the security framework can do)
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

    /*
     
     if client creates the certificate then the server has no default access
     and the user has to be promped to allow keychain access for the server.
     if logging in from a remote instance this causes the remote instance to hang
     indefinately while the local user is queried.
     
     however, on SL, error -67061 is returned which I think means that the server code signature is deemed invalid.
     see http://lists.apple.com/archives/apple-cdsa/2008/Apr/msg00000.html. on Lion things happen as expected.
     
     see http://projects.mugginsoft.net/view.php?id=1159
     
     the solution is to import the keychain with a specific access object rather than the default one.
     
     */

    // the access reference to be applied to the private key needs to be applied here.
    // trying to modify it later in the day is harder and will likely result in the user
    // getting prompted.
	SecKeyImportExportParameters params;
	memset(&params, 0, sizeof(params));
	
    params.flags = 0;
	params.version = SEC_KEY_IMPORT_EXPORT_PARAMS_VERSION;
	params.keyUsage = CSSM_KEYUSE_DECRYPT;
	params.keyAttributes = CSSM_KEYATTR_EXTRACTABLE | CSSM_KEYATTR_PERMANENT;
    
    // process the identity options
    SecAccessRef accessObject = NULL;
    if (identityOptions) {
        NSArray *paths = [identityOptions objectForKey:@"trustedAppPaths"];
        if (paths) {
            
            // build an array of trusted application references
            CFMutableArrayRef apps = CFArrayCreateMutable(NULL, [paths count], &kCFTypeArrayCallBacks);
            
            for (NSString *path in paths) {
                SecTrustedApplicationRef app = NULL;
                err = SecTrustedApplicationCreateFromPath([path cStringUsingEncoding:NSUTF8StringEncoding], &app);
                if (err != noErr) {
                     MLog(RELEASELOG, @"Error creating trusted application from path %d - %@.", err, [self secErrorString:err]);
                    return;
                }
                CFArrayAppendValue(apps, app);
                CFRelease(app);
            }
            
            err = SecAccessCreate((CFStringRef)@"KosmicTask", apps, &accessObject);
            CFRelease(apps);
            if (err != noErr) {
                 MLog(RELEASELOG, @"Error creating certificate access object %d - %@.", err, [self secErrorString:err]);
                return;
            }
            params.accessRef = accessObject;
        }
    }
    
    /*
     
    import the certificate file.
     
     */
	err = SecKeychainItemImport(
										 (CFDataRef) [NSData dataWithContentsOfFile:tmpPath],
										 (CFStringRef) tmpPath,
										 &format,
										 &type,
										 0,
										 &params,
										 keychain,
										 NULL);
	
	if (err != noErr) {
        MLog(RELEASELOG, @"Certificate import error. SecKeychainItemImport returned %d - %@.", err, [self secErrorString:err]);
	}
	
	[[NSFileManager defaultManager] removeItemAtPath:tmpPath error:NULL];
    CFRelease(accessObject);
}

/*
 
 + secErrorString:
 
 */
+ (NSString *)secErrorString:(OSStatus)err
{
    CFStringRef errRef = SecCopyErrorMessageString(err, NULL);
    
    return NSMakeCollectable(errRef);
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
