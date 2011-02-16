/*
 *  serverauthenticate.h
 *  Mother
 *
 *  Created by Jonathan on 23/03/2008.
 *  Copyright 2008 Mugginsoft. All rights reserved.
 *
 */

extern int		AuthCleartext( char *inUsername, char *inPassword );
extern int		AuthCRAMMD5( char *inUsername, char *inChallenge, char *inResponse );
extern int		AuthGSSAPI( int inSocket );

extern int		HandleNewConnection( int inSocket );
extern int		HandleCleartext( int inSocket );
extern int		HandleCRAMMD5( int inSocket );

extern char	*FindUserFromPrincipal( char *inPrincipal );
