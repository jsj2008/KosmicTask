/*Copyright (c) 2007 Extendmac, LLC. <support@extendmac.com>
 
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 */

#import "EMKeychainProxy.h"

#define EM_KEYCHAIN_PROXY_LOGS_ERRORS NO

@implementation EMKeychainProxy

#define EMLog(sel, status) NSLog(@"EMKeychainProxy: Error (%@) - code: %i - reason: %s", NSStringFromSelector(sel), status, GetMacOSStatusErrorString(status))

static EMKeychainProxy* sharedProxy;

+ (id)sharedProxy
{
	if (!sharedProxy)
	{
		sharedProxy = [[EMKeychainProxy alloc] init];
		[sharedProxy setLogsErrors:EM_KEYCHAIN_PROXY_LOGS_ERRORS];
	}
	return sharedProxy;
}
- (void)lockKeychain
{
	SecKeychainLock(NULL);
}
- (void)unlockKeychain
{
	SecKeychainUnlock(NULL, 0, NULL, NO);
}
- (void)setLogsErrors:(BOOL)flag
{
	_logErrors = flag;
}

#pragma mark -
#pragma mark Getting Keychain Items
- (EMGenericKeychainItem *)genericKeychainItemForService:(NSString *)serviceNameString withUsername:(NSString *)usernameString
{
	if (!usernameString || [usernameString length] == 0)
	{
		return nil;
	}
	
	const char *serviceName = [serviceNameString UTF8String];
	const char *username = [usernameString UTF8String];
	
	UInt32 passwordLength = 0;
	char *password = nil;
	
	SecKeychainItemRef item = nil;
	OSStatus returnStatus = SecKeychainFindGenericPassword(NULL, strlen(serviceName), serviceName, strlen(username), username, &passwordLength, (void **)&password, &item);
	if (returnStatus != noErr || !item)
	{
		if (_logErrors)
		{
			EMLog(_cmd, returnStatus);
		}
		return nil;
	}
	NSString *passwordString = [NSString stringWithCString:password length:passwordLength];
	SecKeychainItemFreeContent(NULL, password);	// JM 21-08-08 free the password data
	
	return [EMGenericKeychainItem genericKeychainItem:item forServiceName:serviceNameString username:usernameString password:passwordString];
}
- (EMInternetKeychainItem *)internetKeychainItemForServer:(NSString *)serverString withUsername:(NSString *)usernameString path:(NSString *)pathString port:(int)port protocol:(SecProtocolType)protocol
{
	if (!usernameString || [usernameString length] == 0 || !serverString || [serverString length] == 0)
	{
		return nil;
	}
	const char *server = [serverString UTF8String];
	const char *username = [usernameString UTF8String];
	const char *path = [pathString UTF8String];
	
	if (!pathString || [pathString length] == 0)
	{
		path = "";
	}
	
	UInt32 passwordLength = 0;
	char *password = nil;
	
	SecKeychainItemRef item = nil;
	OSStatus returnStatus = SecKeychainFindInternetPassword(NULL, strlen(server), server, 0, NULL, strlen(username), username, strlen(path), path, port, protocol, kSecAuthenticationTypeDefault, &passwordLength, (void **)&password, &item);
	
	if (returnStatus != noErr || !item)
	{
		if (_logErrors)
		{
			EMLog(_cmd, returnStatus);
		}
		return nil;
	}
	NSString *passwordString = [NSString stringWithCString:password length:passwordLength];
	
	return [EMInternetKeychainItem internetKeychainItem:item forServer:serverString username:usernameString password:passwordString path:pathString port:port protocol:protocol];
}

// MGS 28-12-08
- (BOOL)deleteGenericKeychainItemForService:(NSString *)serviceNameString withUsername:(NSString *)usernameString
{
	if (!usernameString || [usernameString length] == 0)
	{
		return NO;
	}
	
	const char *serviceName = [serviceNameString UTF8String];
	const char *username = [usernameString UTF8String];
	
	UInt32 passwordLength = 0;
	char *password = nil;
	
	SecKeychainItemRef item = nil;
	OSStatus returnStatus = SecKeychainFindGenericPassword(NULL, strlen(serviceName), serviceName, strlen(username), username, &passwordLength, (void **)&password, &item);
	if (returnStatus != noErr || !item)
	{
		if (_logErrors)
		{
			EMLog(_cmd, returnStatus);
		}
		return NO;
	}
	
	returnStatus = SecKeychainItemDelete(item);
	if (returnStatus != noErr)
	{
		EMLog(_cmd, returnStatus);
		return NO;
	}	
	
	return YES;
}

#pragma mark -
#pragma mark Saving Passwords
- (EMGenericKeychainItem *)addGenericKeychainItemForService:(NSString *)serviceNameString withUsername:(NSString *)usernameString password:(NSString *)passwordString
{
	if (!usernameString || [usernameString length] == 0 || !serviceNameString || [serviceNameString length] == 0)
	{
		return nil;
	}	
	const char *serviceName = [serviceNameString UTF8String];
	const char *username = [usernameString UTF8String];
	const char *password = [passwordString UTF8String];
	
	SecKeychainItemRef item = nil;
	OSStatus returnStatus = SecKeychainAddGenericPassword(NULL, strlen(serviceName), serviceName, strlen(username), username, strlen(password), (void *)password, &item);
	
	if (returnStatus != noErr || !item)
	{
		EMLog(_cmd, returnStatus);
		return nil;
	}
	
	return [EMGenericKeychainItem genericKeychainItem:item forServiceName:serviceNameString username:usernameString password:passwordString];
}
- (EMInternetKeychainItem *)addInternetKeychainItemForServer:(NSString *)serverString withUsername:(NSString *)usernameString password:(NSString *)passwordString path:(NSString *)pathString port:(int)port protocol:(SecProtocolType)protocol
{
	if (!usernameString || [usernameString length] == 0 || !serverString || [serverString length] == 0 || !passwordString || [passwordString length] == 0)
	{
		return nil;
	}	
	const char *server = [serverString UTF8String];
	const char *username = [usernameString UTF8String];
	const char *password = [passwordString UTF8String];
	const char *path = [pathString UTF8String];
	
	if (!pathString || [pathString length] == 0)
	{
		path = "";
	}

	SecKeychainItemRef item = nil;
	OSStatus returnStatus = SecKeychainAddInternetPassword(NULL, strlen(server), server, 0, NULL, strlen(username), username, strlen(path), path, port, protocol, kSecAuthenticationTypeDefault, strlen(password), (void *)password, &item);
	
	if (returnStatus != noErr || !item)
	{
		EMLog(_cmd, returnStatus);
		return nil;
	}
	return [EMInternetKeychainItem internetKeychainItem:item forServer:serverString username:usernameString password:passwordString path:pathString port:port protocol:protocol];
}
@end
