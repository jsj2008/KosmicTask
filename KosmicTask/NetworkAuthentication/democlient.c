/*
 
 File: democlient.c
 
 Abstract: Test client to demonstrate client/server auths
 
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

#include <DirectoryService/DirectoryService.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/time.h>
#include "CRAMMD5helper.h"
#include "DSUtility.h"

int AuthCRAMMD5( char *inUsername, char *inChallenge, char *inResponse );

void usage( void )
{
	printf( "Usage:  democlient -u username -p password\n" );
}

int main( int argc, char *argv[] )
{
	int		ch;
	char	*pUsername	= NULL;
	char	*pPassword	= NULL;

	// parse out our arguments
	while ((ch = getopt(argc, argv, "u:p:")) != -1) {
		switch (ch) {
			
			case 'u':
				pUsername = optarg;
				break;
			case 'p':
				pPassword = optarg;
				break;
			case '?':
			default:
				usage();
				return 1;
		}
	}

		
	// otherwise, we should have a username / password too
	if( pUsername == NULL || strlen(pUsername) == 0 || pPassword == NULL || strlen(pPassword) == 0 ) {
		usage();
		return 1;
	}

	 unsigned char	pChallenge[255]	= { 0, };
	 char			pHostname[128]	= { 0, };
	 char			*pResponse		= NULL;
	 struct timeval	stCurrentTime;
	 int				iResult			= -1;
	 
	 // Since CRAM-MD5 was requested, let's generate a challenge and send it to the client
	 // using example method in RFC 1460, page 12.
	 gethostname( pHostname, 127 );
	 gettimeofday( &stCurrentTime, NULL ); // assume no error occurred
	 snprintf( (char *)pChallenge, 255, "<%ld.%ld@%s>", (long) getpid(), stCurrentTime.tv_sec, pHostname );
	 
	// then create the response based on that challenge
	unsigned char	pHash[17]		= { 0, };
	unsigned char	pHashHex[33]	= { 0, };
	int				i;

	// zero out the hash buffer in advance
	bzero( pHash, 17 );

	// Compute keyed-md5 hash of password and challenge.
	long ChallenLength = strlen((char *)pChallenge);
	long PasswordLength = strlen(pPassword);
	CalcMD5( (char *)pChallenge, ChallenLength, pPassword, PasswordLength, pHash );

	// Prepare a Hex string representation of the hash, grouping into 2-byte Hex values.
	bzero( pHashHex, 33 );
	for( i=0; i < 16; i++ ) {
		sprintf( (char *)&pHashHex[i<<1], "%02x", pHash[i]);
	}

	// Add the NULL terminator
	pHashHex[32] = 0; 
	pResponse = (char *)pHashHex;

	 // here is where we authenticate the user using Open Directory
	 iResult = AuthCRAMMD5( pUsername, (char *)pChallenge, pResponse );
	 
	 // send a response
	 if( iResult == eDSNoErr ) {
		 printf( "Success\n" );
	 } else {
		 printf( "Failure\n" );
	 }

	return 0;
}

int AuthCRAMMD5( char *inUsername, char *inChallenge, char *inResponse )
{
	tDirReference		dsRef			= 0;
	tDirNodeReference	dsSearchNodeRef	= 0;
	tDirNodeReference	dsUserNodeRef	= 0;
	tDirStatus			dsStatus;
	char				*pRecordName	= NULL;
	char				*pNodeName		= NULL;
	
	// Key steps to Authenticating a user:
	//	- First locate the user in the directory
	//	- Open Directory Service reference
	//	- Locate and open the Search Node
	//	- Locate the user's official RecordName and Directory Node based on the username provided
	//	- Then use authentication appropriate for the type of method
	
	// Open Directory Services reference
	dsStatus = dsOpenDirService( &dsRef );
	if( dsStatus == eDSNoErr ) {
		
		// use utility function to open the search node
		dsStatus = OpenSearchNode( dsRef, &dsSearchNodeRef );
		if( dsStatus == eDSNoErr ) {
			
			// use utility function to locate the user information
			dsStatus = LocateUserRecordNameAndNode( dsRef, dsSearchNodeRef, inUsername, &pRecordName, &pNodeName );
			if( dsStatus == eDSNoErr ) {
				
				// we should have values available, but let's check to be sure
				if( pNodeName != NULL && pNodeName[0] != '\0' && 
				   pRecordName != NULL && pRecordName[0] != '\0' )
				{
					// need to create a tDataListPtr from the "/plugin/node" path, using "/" as the separator
					tDataListPtr dsUserNodePath = dsBuildFromPath( dsRef, pNodeName, "/" );
					
					// attempt to open the node provided
					dsStatus = dsOpenDirNode( dsRef, dsUserNodePath, &dsUserNodeRef );
					if( dsStatus == eDSNoErr ) {
						
						// Here is the Utility function that will do the authentication for us
						dsStatus = DoChallengeResponseAuth( dsRef, dsUserNodeRef, kDSStdAuthCRAM_MD5, pRecordName, 
														   inChallenge, strlen(inChallenge), 
														   inResponse, strlen(inResponse) );
						
						// Determine if successful.  There are cases where you may receive other errors
						// such as eDSAuthPasswordExpired.
						if( dsStatus == eDSNoErr ) {
							printf( "Successful:  CRAM-MD5 Authentication successful for user '%s'\n", pRecordName );
						} else {
							printf( "Failure:  CRAM-MD5 Authentication for user '%s' - %d\n", pRecordName, dsStatus );
						}
					}
					
					// free the data list as it is no longer needed
					dsDataListDeallocate( dsRef, dsUserNodePath );
					free( dsUserNodePath );
					dsUserNodePath = NULL;
				}
				
				// need to free any node name that may have been returned
				if( pNodeName != NULL ) {
					free( pNodeName );
					pNodeName = NULL;
				}
				
				// need to free any record name that may have been returned
				if( pRecordName != NULL ) {
					free( pRecordName );
					pRecordName = NULL;
				}
			}
			
			// close the search node cause we are done here
			dsCloseDirNode( dsSearchNodeRef );
			dsSearchNodeRef = 0;
			
		} else {
			printf( "Unable to locate and open the Search node\n" );
			return 1;
		}
		
		// need to close Directory Services at this point
		dsCloseDirService( dsRef );
		dsRef = 0;
	}
	
    return dsStatus;
}

