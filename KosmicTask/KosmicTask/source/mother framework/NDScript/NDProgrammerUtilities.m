/*
 *  NDProgrammerUtilities.m
 *  NDScriptData
 *
 *  Created by Nathan Day on Sat May 01 2004.
 *  Copyright (c) 2004 Nathan Day. All rights reserved.
 *
 */

#include "NDProgrammerUtilities.h"

BOOL NDLogFalseBody( const BOOL aCond, const char * aFileName, const char * aFuncName, const unsigned int aLine, const char * aCodeLine )
{
#ifdef NDAssertLogging
	if( aCond == NO )
		[[NSException raise:NSInternalInconsistencyException format:@"[%@] Condition false:\n\t%s\n\tfile: %s\n\tfunction: %s\n\tline: %u.\n", [NSDate date], aFuncName, aCodeLine, aFileName, aLine];
#else
	if( aCond == NO )
		fprintf( stderr, "[%s] Condition false:\n\t%s\n\tfile: %s\n\tfunction: %s\n\tline: %u.\n", [[[NSDate date] description] UTF8String], aFuncName, aCodeLine, aFileName, aLine );
#endif

	return aCond;
}

BOOL NDLogOSStatusBody( const OSStatus anError, const char * aFileName, const char * aFuncName, const unsigned int aLine, const char * aCodeLine, NSString*(*aErrToStringFunc)(const OSStatus) )
{
#ifdef NDAssertLogging
	if( anError != noErr ) {
		[NSException raise:NSInternalInconsistencyException format:@"Error result [%@] OSStatus %li:\n\t%s\n\tfile: %s\n\tfunction: %s\n\tline: %u.\n", [NSDate date], anError, aCodeLine, aFileName, aFuncName, aLine];
	}
#else
	if( anError != noErr )
	{
		if( aErrToStringFunc != NULL ) {
			fprintf( stderr, "Error result [%s] OSStatus %li:\n\t%s\n\tfile: %s\n\tfunction: %s\n\tline: %u\n\tdescription: %s\n", [[[NSDate date] description] UTF8String], anError, aCodeLine, aFileName, aFuncName, aLine, [aErrToStringFunc(anError) UTF8String] );
		} else {
			fprintf( stderr, "Error result [%s] OSStatus %li:\n\t%s\n\tfile: %s\n\tfunction: %s\n\tline: %u\n", [[[NSDate date] description] UTF8String], anError, aCodeLine, aFileName, aFuncName, aLine );
		}
	}
#endif

	return anError == noErr;
}

#ifndef NDTurnLoggingOff
void NDUntestedMethodBody( const char * aFileName, const char * aFuncName, const unsigned int aLine )
{
	fprintf( stderr, "WARNING: The function %s has not been tested\n\tfile: %s\n\tline: %u.\n", aFileName, aFuncName, aLine );
}
#endif
		 
BOOL NDSoftParamAssertBody( const BOOL aCond, const char * aFileName, const char * aFuncName, const unsigned int aLine, const char * aCodeLine )
{
#ifdef NDAssertLogging
	if( aCond == NO )
		[[NSException raise:NSInternalInconsistencyException format:@"[%@] Condition false:\n\t%s\n\tfile: %s\n\tfunction: %s\n\tline: %u.\n", [NSDate date], aFuncName, aCodeLine, aFileName, aLine];
#else
	if( aCond == NO )
		fprintf( stderr, "[%s] Condition false:\n\t%s\n\tfile: %s\n\tfunction: %s\n\tline: %u.\n", [[[NSDate date] description] UTF8String], aFuncName, aCodeLine, aFileName, aLine );
#endif

	return aCond;
}
