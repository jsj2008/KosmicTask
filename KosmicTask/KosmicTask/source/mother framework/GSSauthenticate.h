/*
 
 File: GSSauthenticate.h
 
 Abstract: Simplified functions to help with GSSAPI authentications on
           server side.
 
 Version: <1.0>
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Computer, Inc. ("Apple") in consideration of your agreement to the
 following terms, and your use, installation, modification or
 redistribution of this Apple software constitutes acceptance of these
 terms.  If you do not agree with these terms, please do not use,
 install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Computer,
 Inc. may be used to endorse or promote products derived from the Apple
 Software without specific prior written permission from Apple.  Except
 as expressly stated in this notice, no other rights or licenses, express
 or implied, are granted by Apple herein, including but not limited to
 any patent rights that may be infringed by your derivative works or by
 other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright © 2005 Apple Computer, Inc., All Rights Reserved
 
 */

/*!
	@function	AuthenticateGSS
	@abstract   Will authenticate a user, but does not verify the user is a valid local account
	@discussion This function will validate the GSS credentials provided, but does not verify the user has a
				matching / valid user account, or whether SACLs are in affect for this service.
	@param		inToken The data received from the client
	@param		inTokenLen Is the length of the data received in inToken
	@param		outToken A point to a void buffer of data to be sent back to calling client
	@param		outTokenLen The length of the data in outToken to be returned to client
	@param      inOutServiceName NULL = determine service after auth verified, non-NULL, pointing to service to be used
	@param		outUserPrinc Will be the user principal that authenticated to the service
	@param		inOutGSScontext Is the gss_context that should be used for all further GSS interaction
	@param		inOutGSScreds Are the GSS creds that are to be used if pre-determined with AcquireGSSCredentials, otherwise
					returned after negotiation
	@result     Will return various errors.  If GSS_S_CONTINUE_NEEDED is returned, then the outToken data must
				be sent to the calling client.  Any further tokens need to be sent back into this call until
				GSS_S_COMPLETE is returned.  In all cases, whenever outToken has a value, it must be sent
				to the client.
*/
OM_uint32 AuthenticateGSS( char *inToken, int inTokenLen, char **outToken, size_t *outTokenLen, char **inOutServiceName, 
						   char **outUserPrinc, gss_ctx_id_t *inOutGSScontext, gss_cred_id_t *inOutGSScreds );


/*!
    @function	AcquireGSSCredentials
    @abstract   Will attempt to acquire credentials for the service name provided using keytab
    @param      inServiceName is a service name such as "ldap@hostname.domain.com" or "host@hostname.domain.com"
    @result     Will return 0 if success, -1 if failed
*/
int AcquireGSSCredentials( const char *inServiceName, gss_cred_id_t *outServiceCredentials );
