/*
 *  NDComponentInstance.m
 *  NDScriptData
 *
 *  Created by Nathan Day on Tue May 20 2003.
 *  Copyright (c) 2002 Nathan Day. All rights reserved.
 */

#import "NDComponentInstance.h"
#import "NSAppleEventDescriptor+NDScriptData.h"
#include "NDProgrammerUtilities.h"

const OSType		kFinderCreatorCode = 'MACS';

const NSString		* NDAppleScriptOffendingObject = @"Error Offending Object",
					* NDAppleScriptPartialResult = @"Error Partial Result";

static OSErr NDComponentAppleEventSendProc( const AppleEvent *theAppleEvent, AppleEvent *reply, AESendMode sendMode, AESendPriority sendPriority, SInt32 timeOutInTicks, AEIdleUPP idleProc, AEFilterUPP filterProc, SRefCon refCon );

/*
	category interface NDComponentInstance (Private)
 */
@interface NDComponentInstance (Private)
- (ComponentInstance)instanceRecord;
@end

/*
	class implementation NDComponentInstance
 */
@implementation NDComponentInstance

static NDComponentInstance		* sharedComponentInstance = nil;

#pragma mark -
#pragma mark Class methods
/*
	+ sharedComponentInstance
 */
+ (id)sharedComponentInstance
{
	if( sharedComponentInstance == nil )
		sharedComponentInstance = [[self alloc] init];
	NSAssert( sharedComponentInstance != nil, @"Could not create shared Component Instance" );
	return sharedComponentInstance;
}

/*
	+ closeSharedComponentInstance
 */
+ (void)closeSharedComponentInstance
{
	[sharedComponentInstance release];
	sharedComponentInstance = nil;
}

/*
	+ findNextComponent
 */
+ (Component)findNextComponent
{
	
	ComponentDescription		theReturnCompDesc;
	static Component			theLastComponent = NULL;
	ComponentDescription		theComponentDesc;

	theComponentDesc.componentType = kOSAComponentType;
	theComponentDesc.componentSubType = kOSAGenericScriptingComponentSubtype;
	theComponentDesc.componentManufacturer = 0;
	theComponentDesc.componentFlags =  kOSASupportsCompiling | kOSASupportsGetSource | kOSASupportsAECoercion | kOSASupportsAESending | kOSASupportsConvenience | kOSASupportsDialects | kOSASupportsEventHandling;

	theComponentDesc.componentFlagsMask = theComponentDesc.componentFlags;

	//long componentCount = CountComponents(&theComponentDesc);	
	
	do
	{
		theLastComponent = FindNextComponent( theLastComponent, &theComponentDesc );

		//long componentInstances = CountComponentInstances(theLastComponent);
 	}
	while( !(GetComponentInfo( theLastComponent, &theReturnCompDesc, NULL, NULL, NULL ) == noErr && theComponentDesc.componentSubType == kOSAGenericScriptingComponentSubtype) );
	
	/*
	BOOL done = NO;
	do
	{
		// header states that FindNextComponent and GetComponentInfo are both threadsafe
		component = FindNextComponent( theLastComponent, &theComponentDesc );
		if (component) {
			OSErr infoStat = GetComponentInfo( component, &theReturnCompDesc, NULL, NULL, NULL );
			if (infoStat == noErr && theComponentDesc.componentSubType == kOSAGenericScriptingComponentSubtype) {
				theLastComponent = component;
				done = YES;
			}
		} else {
			done= YES;
		}
 	}
	while(!done);
*/
	
	return theLastComponent;
}

/*
	+ componentInstance
 */
+ (id)componentInstance
{
	return [[[self alloc] init] autorelease];
}

/*
	+ findNextcomponentInstance
 */
+ (id)findNextComponentInstance {
	Component osaComponent = [self findNextComponent];
	if (!osaComponent) return NULL;
	
	return [self componentInstanceWithComponent:osaComponent];
}

/*
	+ componentInstanceWithComponent:
 */
+ (id)componentInstanceWithComponent:(Component)aComponent
{
	return [[[self alloc] initWithComponent:aComponent] autorelease];
}

#pragma mark -
#pragma mark Instance control
/*
	- init
 */
- (id)init
{
	return [self initWithComponent:NULL];
}

/*
	- initWithComponent:
 */
- (id)initWithComponent:(Component)aComponent
{
	if( (self = [super init]) != nil )
	{
		if( aComponent == NULL )
		{
			if( (instanceRecord = OpenDefaultComponent( kOSAComponentType, kAppleScriptSubtype )) == NULL )
			{
				[self release];
				self = nil;
				NSLog(@"Could not open connection with default AppleScript component");
			}
		}
		else if( (instanceRecord = OpenComponent( aComponent )) == NULL )
		{
			[self release];
			self = nil;
			NSLog(@"Could not open connection with component");
		}
	}
	return self;
}

/*
	- dealloc
 */
-(void)dealloc
{
	[self setAppleEventSendTarget:nil];
	[self setActiveTarget:nil];
	[self setAppleEventResumeHandler:nil];

	if( instanceRecord != NULL )
	{
		CloseComponent( instanceRecord );			// this core dump with Garbage Collection
		instanceRecord = NULL;
	}
	[super dealloc];
}

/*
 - finalize
 */
- (void)finalize
{
	[super finalize];
}

/*
	- dispose
 */
- (void)dispose
{
	/* set these to nil so the default values can be set if required */
	[self setAppleEventSendTarget:nil];
	[self setActiveTarget:nil];
	[self setAppleEventResumeHandler:nil];
	
	if( instanceRecord != NULL )
	{
		CloseComponent( instanceRecord );	
		instanceRecord = NULL;
	}
}

#pragma mark -
#pragma mark Target
/*
	- setDefaultTarget:
 */
- (void)setDefaultTarget:(NSAppleEventDescriptor *)aDefaultTarget
{
	if( OSASetDefaultTarget( [self instanceRecord], [aDefaultTarget aeDesc] ) != noErr )
		NSLog( @"Could not set default target" );
}

/*
	- setDefaultTargetAsCreator:
 */
- (void)setDefaultTargetAsCreator:(OSType)aCreator
{
	NSAppleEventDescriptor	* theAppleEventDescriptor;

	theAppleEventDescriptor = [NSAppleEventDescriptor descriptorWithDescriptorType:typeApplSignature data:[NSData dataWithBytes:&aCreator length:sizeof(aCreator)]];
	[self setDefaultTarget:theAppleEventDescriptor];
}

/*
	- setFinderAsDefaultTarget
 */
- (void)setFinderAsDefaultTarget
{
	[self setDefaultTargetAsCreator:kFinderCreatorCode];
}

/*
	- setAppleEventSendTarget:
 */
- (void)setAppleEventSendTarget:(id<NDScriptDataSendEvent>)aTarget
{
	[self setAppleEventSendTarget:aTarget currentProcessOnly:NO];
}

/*
	- setExecuteAppleEventInMainThread:
 */
- (void)setExecuteAppleEventInMainThread:(BOOL)aFlag
{
	executeAppleEventInMainThread = aFlag;
}

/*
	- executeAppleEventInMainThread
 */
- (BOOL)executeAppleEventInMainThread
{
	return executeAppleEventInMainThread;
}

/*
	- setAppleEventSendTarget:
 */
- (void)setAppleEventSendTarget:(id<NDScriptDataSendEvent>)aTarget currentProcessOnly:(BOOL)aFlag
{
	sendAppleEvent.currentProcessOnly = aFlag;
	if( aTarget != sendAppleEvent.target )
	{
		NSParameterAssert( sizeof(long) == sizeof(id) );
		
		/*	need to save the default send proceedure as we will call it in our send proceedure	*/
		if( aTarget != nil )
		{
			if( defaultSendProcPtr == NULL )		// need to save this so we can restor it
			{
				[self setSendProc:NDComponentAppleEventSendProc];
			}

			[sendAppleEvent.target release];
			sendAppleEvent.target = [aTarget retain];
		}
		else
		{
			[sendAppleEvent.target release];
			sendAppleEvent.target = nil;

			[self restoreSendProc];
		}
	}
}

/*
	- appleEventSendTarget
 */
- (id<NDScriptDataSendEvent>)appleEventSendTarget
{
	return sendAppleEvent.target;
}

/*
	- appleEventSendCurrentProcessOnly
 */
- (BOOL)appleEventSendCurrentProcessOnly
{
	return sendAppleEvent.currentProcessOnly;
}

/*
	- setActiveTarget:
 */
	static OSErr		AppleScriptActiveProc( SRefCon aSelf );
- (void)setActiveTarget:(id<NDScriptDataActive>)aTarget
{
	if( aTarget != activeTarget )
	{
		NSParameterAssert( sizeof(long) == sizeof(id) );

		if( aTarget != nil )
		{
			/*	need to save the default active proceedure as we will call it in our active proceedure	*/
			if( defaultActiveProcPtr == NULL )
			{
				ComponentInstance		theComponent = [self instanceRecord];

				NSAssert( OSAGetActiveProc(theComponent, &defaultActiveProcPtr, &defaultActiveProcRefCon ) == noErr, @"Could not get default AppleScript active procedure");
				NSAssert( OSASetActiveProc( theComponent, AppleScriptActiveProc , (SRefCon)self ) == noErr, @"Could not set AppleScript active procedure.");
			}

			[activeTarget release];
			activeTarget = [aTarget retain];
		}
		else if( defaultActiveProcPtr == NULL )
		{
			[activeTarget release];
			activeTarget = nil;
			NSAssert( OSASetActiveProc( [self instanceRecord], defaultActiveProcPtr, defaultActiveProcRefCon ) == noErr, @"Could not set default active procedure.");
			defaultActiveProcPtr = NULL;
			defaultActiveProcRefCon = 0;
		}
	}
}

/*
	- activeTarget
 */
- (id<NDScriptDataActive>)activeTarget
{
	return activeTarget;
}

#pragma mark -
#pragma mark Event Handlers
#if 0
/*
	- setAppleEventSpecialHandler:
 */
- (void)setAppleEventSpecialHandler:(id<NDScriptDataAppleEventSpecialHandler>)aHandler
{
	if( aHandler != appleEventSpecialHandler )
	{
		[appleEventSpecialHandler release];
		appleEventSpecialHandler = [aHandler retain];
	}
}

/*
	- appleEventSpecialHandler
 */
- (id<NDScriptDataAppleEventSpecialHandler>)appleEventSpecialHandler
{
	return appleEventSpecialHandler;
}
#endif

/*
	- setAppleEventResumeHandler:
 */
	static OSErr AppleEventResumeHandler(const AppleEvent * anAppleEvent, AppleEvent * aReply, SRefCon aSelf );
- (void)setAppleEventResumeHandler:(id<NDScriptDataAppleEventResumeHandler>)aHandler
{
	if( aHandler != appleEventResumeHandler )
	{
		if( defaultResumeProcPtr == NULL )
			NDLogOSAError( OSAGetResumeDispatchProc ( [self instanceRecord], &defaultResumeProcPtr, &defaultResumeProcRefCon ) );

		NDLogOSAError( OSASetResumeDispatchProc( [self instanceRecord], AppleEventResumeHandler, (SRefCon)self ) );
		[appleEventResumeHandler release];
		appleEventResumeHandler = [aHandler retain];
	}
}

/*
	- appleEventResumeHandler
 */
- (id<NDScriptDataAppleEventResumeHandler>)appleEventResumeHandler
{
	return appleEventResumeHandler;
}

/*
	- sendAppleEvent:sendMode:sendPriority:timeOutInTicks:idleProc:filterProc:
 */
- (NSAppleEventDescriptor *)sendAppleEvent:(NSAppleEventDescriptor *)anAppleEventDescriptor sendMode:(AESendMode)aSendMode sendPriority:(AESendPriority)aSendPriority timeOutInTicks:(SInt32)aTimeOutInTicks idleProc:(AEIdleUPP)anIdleProc filterProc:(AEFilterUPP)aFilterProc
{
	NSAppleEventDescriptor		* theReplyAppleEventDescriptor = nil;
	AEDesc							theReplyDesc = { typeNull, NULL };

	NSParameterAssert( defaultSendProcPtr != NULL );
	
	NDLogOSAError( defaultSendProcPtr( [anAppleEventDescriptor aeDesc], &theReplyDesc, aSendMode, aSendPriority, aTimeOutInTicks, anIdleProc, aFilterProc, defaultSendProcRefCon ) );
	{
		theReplyAppleEventDescriptor = [NSAppleEventDescriptor descriptorWithAEDesc:&theReplyDesc];
	}
	
	return theReplyAppleEventDescriptor;
}

/*
 * appleScriptActive
 */
- (BOOL)appleScriptActive
{
	NSParameterAssert( defaultActiveProcPtr != NULL );
	return defaultActiveProcPtr( defaultActiveProcRefCon ) == noErr;
}

/*
	- handleResumeAppleEvent:
 */
- (NSAppleEventDescriptor *)handleResumeAppleEvent:(NSAppleEventDescriptor *)aDescriptor
{
	AEDesc		theReplyDesc = { typeNull, NULL };
	return defaultResumeProcPtr([aDescriptor aeDesc], &theReplyDesc, defaultResumeProcRefCon ) == noErr ? [NSAppleEventDescriptor descriptorWithAEDesc:&theReplyDesc] : nil;
}


/*
	- error
 */
- (NSDictionary *)error
{
	AEDesc					theDescriptor = { typeNull, NULL };
	unsigned int			theIndex;
	NSMutableDictionary	* theDictionary = [NSMutableDictionary dictionaryWithCapacity:7];

    // in moving from 32bit to 64 bit some types were removed.
    // see AEDataModel.h
	struct { const NSString * key; const DescType desiredType; const OSType selector; }
			theResults[] = {
			{ NSAppleScriptErrorMessage, typeText, kOSAErrorMessage },
			{ NSAppleScriptErrorNumber, typeSInt16, kOSAErrorNumber },
			{ NSAppleScriptErrorAppName, typeText, kOSAErrorApp },
			{ NSAppleScriptErrorBriefMessage, typeText, kOSAErrorBriefMessage },
			{ NSAppleScriptErrorRange, typeOSAErrorRange, kOSAErrorRange },
			{ NDAppleScriptOffendingObject, typeObjectSpecifier, kOSAErrorOffendingObject, },
			{ NDAppleScriptPartialResult, typeBest, kOSAErrorPartialResult },
			{ nil, 0, 0 }
			};
	for( theIndex = 0; theResults[theIndex].key != nil; theIndex++ )
	{
		if( OSAScriptError([self instanceRecord], theResults[theIndex].selector, theResults[theIndex].desiredType, &theDescriptor ) == noErr )
		{
			[theDictionary setObject:(id)[[NSAppleEventDescriptor descriptorWithAEDesc:&theDescriptor] objectValue] forKey:(id)theResults[theIndex].key];
		}
	}

	return theDictionary;
}

/*
	- name
 */
- (NSString *)name
{
	AEDesc		theDesc = { typeNull, NULL };
	NSString		* theName = nil;
	if ( OSAScriptingComponentName( [self instanceRecord], &theDesc) == noErr )
		theName = [[NSAppleEventDescriptor descriptorWithAEDesc:&theDesc] stringValue];

	return theName;
}

/*
	- description
 */
- (NSString *)description
{
	NSString		* theName = [self name];
	return theName == nil
		? [@"NDComponentInstance name:" stringByAppendingString:theName]
		: @"NDComponentInstance name: not available";
}

#pragma mark -
#pragma mark Equality
/*
	- isEqualToComponentInstance:
 */
- (BOOL)isEqualToComponentInstance:(NDComponentInstance *)aComponentInstance
{
	return aComponentInstance == self || [aComponentInstance instanceRecord] == [self instanceRecord];
}

/*
	- isEqualTo:
 */
- (BOOL)isEqualTo:(id)anObject
{
	return anObject == self || ([anObject isKindOfClass:[self class]] && [self isEqualToComponentInstance:anObject]);
}

/*
	- hash
 */
- (NSUInteger)hash
{
	return (NSUInteger)instanceRecord;
}

#pragma mark -
#pragma mark Copying
/*
 - copyWithZone:
 */
- (id)copyWithZone:(NSZone *)aZone
{
#pragma unused(aZone)
	
	return [self retain];
}


#pragma mark -
#pragma mark OSA procs
/*
 
 - setSendProc:
 
 */
- (void)setSendProc:(OSASendUPP) sendProc
{
	OSASendUPP				theDefaultSendProcPtr;
	SRefCon				theDefaultSendProcRefCon;
	ComponentInstance		theComponent = [self instanceRecord];
	
	NSAssert( OSAGetSendProc( theComponent, &theDefaultSendProcPtr, &theDefaultSendProcRefCon) == noErr, @"Could not get default AppleScript send procedure");
	
	/*
	 make sure we haven't already set the send procedure for this component instance.
	 */
	if( theDefaultSendProcPtr != sendProc )
	{
		defaultSendProcPtr = theDefaultSendProcPtr;
		defaultSendProcRefCon = theDefaultSendProcRefCon;
	}
	else	// get the original component instance
	{
		NSLog( @"The send procedure for the component instance for this NDComponentInstance is already set." );
		defaultSendProcPtr = ((NDComponentInstance*)theDefaultSendProcRefCon)->defaultSendProcPtr;
		defaultSendProcRefCon = ((NDComponentInstance*)theDefaultSendProcRefCon)->defaultSendProcRefCon;
	}
	NSAssert( OSASetSendProc( theComponent, sendProc, (SRefCon)self ) == noErr, @"Could not set send procedure" );
}

/*
 
 restore send proc
 
 */
- (void)restoreSendProc
{
	NSParameterAssert( defaultSendProcPtr != NULL );
	
	NSAssert( OSASetSendProc( [self instanceRecord], defaultSendProcPtr, defaultSendProcRefCon ) == noErr, @"Could not restore default send procedure");

	defaultSendProcPtr = NULL;
	defaultSendProcRefCon = 0;

}
/*
 * function NDComponentAppleEventSendProc
 */
OSErr NDComponentAppleEventSendProc( const AppleEvent *anAppleEvent, AppleEvent *aReply, AESendMode aSendMode, AESendPriority aSendPriority, SInt32 aTimeOutInTicks, AEIdleUPP anIdleProc, AEFilterUPP aFilterProc, SRefCon aSelf )
{
	NDComponentInstance			* self = (id)aSelf;
	OSErr						theError = errOSASystemError;
	id							theSendTarget = [self appleEventSendTarget];
	BOOL						theCurrentProcessOnly = [self appleEventSendCurrentProcessOnly];
	NSAppleEventDescriptor		* theAppleEventDescReply,
								* theAppleEventDescriptor = nil;
	
	NSCParameterAssert( self != nil );
	
	/*	if we have an instance, it has a target and we can create a NSAppleEventDescriptor	*/
	if( theSendTarget != nil && theAppleEventDescriptor != [[[NSAppleEventDescriptor alloc] initWithAEDesc:anAppleEvent] autorelease] && (theCurrentProcessOnly == NO || [theAppleEventDescriptor isTargetCurrentProcess]) )
	{	
		theAppleEventDescReply = [theSendTarget sendAppleEvent:theAppleEventDescriptor sendMode:aSendMode sendPriority:aSendPriority timeOutInTicks:aTimeOutInTicks idleProc:anIdleProc filterProc:aFilterProc];

		if( [theAppleEventDescReply getAEDesc:(AEDesc*)aReply] )
		{
			theError = noErr;			// NO ERROR
		}
	}
	else if( self->defaultSendProcPtr != NULL )
	{
		NDLogOSAError(theError = (self->defaultSendProcPtr)( anAppleEvent, aReply, aSendMode, aSendPriority, aTimeOutInTicks, anIdleProc, aFilterProc, self->defaultSendProcRefCon ));
	}
	else
		NSLog( @"Failed to send" );
	
	[theAppleEventDescriptor release];

	return theError;
}

/*
 * function AppleScriptActiveProc
 */
static OSErr AppleScriptActiveProc( SRefCon aSelf )
{
	NDComponentInstance	* self = (id)aSelf;
	id							theActiveTarget = [self activeTarget];
	OSErr						theError = errOSASystemError;

	NSCParameterAssert( self != nil );
	
	if( theActiveTarget != nil )
		theError = [theActiveTarget appleScriptActive] ? noErr : errOSASystemError;
	else
		theError = (self->defaultActiveProcPtr)( self->defaultActiveProcRefCon );

	return theError;
}

#if 0
static OSErr AppleEventSpecialHandler(const AppleEvent * anAppleEvent, AppleEvent * aReply, long aSelf )
{
	NDComponentInstance			* self = (id)aSelf;
	OSErr								theError = errAEEventNotHandled;
	id									theSpecialHandler = [self appleEventSpecialHandler];
	NSAppleEventDescriptor		* theResult = nil;
	
	NSCParameterAssert( self != nil );

	if( theSpecialHandler == nil )
		theSpecialHandler = self;
	
	theResult = [theSpecialHandler handleSpecialAppleEvent:[NSAppleEventDescriptor descriptorWithAEDesc:anAppleEvent]];
	if( theResult )
	{
		NSCParameterAssert( [theResult getAEDesc:aReply] );
		theError = noErr;
	}
	else
		theError = errOSASystemError;
	
	return theError;
}
#endif

static OSErr AppleEventResumeHandler(const AppleEvent * anAppleEvent, AppleEvent * aReply, SRefCon aSelf )
{
	NDComponentInstance			* self = (id)aSelf;
	OSErr								theError = errAEEventNotHandled;
	id									theResumeHandler = [self appleEventResumeHandler];
	NSAppleEventDescriptor		* theResult = nil;	

	NSCParameterAssert( self != nil );

	if( theResumeHandler == nil )
		theResumeHandler = self;

	theResult = [theResumeHandler handleResumeAppleEvent:[NSAppleEventDescriptor descriptorWithAEDesc:anAppleEvent]];
	
	if( theResult )
	{
		NSCParameterAssert( [theResult getAEDesc:aReply] );
		theError = noErr;
	}
	else
		theError = errOSASystemError;
	
	return theError;
}

@end

/*
	category implementation NDComponentInstance (Private)
 */
#pragma mark -
@implementation NDComponentInstance (Private)

/*
	- instanceRecord
 */
- (ComponentInstance)instanceRecord
{
#ifdef DEBUG_NDScript
	NSParameterAssert( instanceRecord != NULL );
#endif
	return instanceRecord;
}

@end

#pragma mark -
#pragma mark Functions

/*
 
 string for OSA error
 
 */
NSString * stringForOSAError( const OSStatus anError )
{
	NSString		* theString = nil;
	switch( anError )
	{
		case errOSACantCoerce:
			theString = @"(errOSACantCoerce) A value can't be coerced to the desired type.";
			break;
		case OSAMissingParameter:
			theString = @"(OSAMissingParameter) A parameter is missing for a function invocation.";
			break;
		case errOSACorruptData:
			theString = @"(errOSACorruptData) Some data could not be read.";
			break;
		case errOSATypeError:
			theString = @"(errOSATypeError) Same as errAEWrongDataType; wrong descriptor type.";
			break;
		case OSAMessageNotUnderstood:
			theString = @"(OSAMessageNotUnderstood) A message was sent to an object that didn't handle it.";
			break;
		case OSAUndefinedHandler:
			theString = @"(OSAUndefinedHandler) A function to be returned doesn't exist.";
			break;
		case OSAIllegalIndex:
			theString = @"(OSAIllegalIndex) An index was out of range. Specialization of errOSACantAccess.";
			break;
		case OSAIllegalRange:
			theString = @"(OSAIllegalRange) The specified range is illegal. Specialization of errOSACantAccess.";
			break;
		case OSAParameterMismatch:
			theString = @"(OSAParameterMismatch) The wrong number of parameters were passed to the function, or a parameter pattern cannot be matched.";
			break;
		case OSAIllegalAccess:
			theString = @"(OSAIllegalAccess) A container can not have the requested object.";
			break;
		case errOSACantAccess:
			theString = @"(errOSACantAccess) An object is not found in a container.";
			break;
		case errOSARecordingIsAlreadyOn:
			theString = @"(errOSARecordingIsAlreadyOn) Recording is already on. Available only in version 1.0.1 or greater.";
			break;
		case errOSASystemError:
			theString = @"(errOSASystemError) Scripting component error.";
			break;
		case errOSAInvalidID:
			theString = @"(errOSAInvalidID) Invalid script id.";
			break;
		case errOSABadStorageType:
			theString = @"(errOSABadStorageType) Script doesn’t seem to belong to AppleScript.";
			break;
		case errOSAScriptError:
			theString = @"(errOSAScriptError) Script error.";
			break;
		case errOSABadSelector:
			theString = @"(errOSABadSelector) Invalid selector given.";
			break;
		case errOSASourceNotAvailable:
			theString = @"(errOSASourceNotAvailable) Invalid access.";
			break;
		case errOSANoSuchDialect:
			theString = @"(errOSANoSuchDialect) Source not available.";
			break;
		case errOSADataFormatObsolete:
			theString = @"(errOSADataFormatObsolete) No such dialect.";
			break;
		case errOSADataFormatTooNew:
			theString = @"(errOSADataFormatTooNew) Data couldn’t be read because its format is obsolete.";
			break;
		case errOSAComponentMismatch:
			theString = @"(errOSAComponentMismatch) Parameters are from two different components.";
			break;
		case errOSACantOpenComponent:
			theString = @"(errOSACantOpenComponent) Can't connect to system with that ID.";
			break;
		case errOSAGeneralError:
			theString = @"(errOSAGeneralError) No actual error code is to be returned.";
			break;
		case errOSADivideByZero:
			theString = @"(errOSADivideByZero) An attempt to divide by zero was made.";
			break;
		case errOSANumericOverflow:
			theString = @"(errOSANumericOverflow) An integer or real value is too large to be represented.";
			break;
		case errOSACantLaunch:
			theString = @"(errOSACantLaunch) An application can't be launched, or when it is, remote and program linking is not enabled.";
			break;
		case errOSAAppNotHighLevelEventAware:
			theString = @"(errOSAAppNotHighLevelEventAware) An application can't respond to AppleEvents.";
			break;
		case errOSACorruptTerminology:
			theString = @"(errOSACorruptTerminology) An application's terminology resource is not readable.";
			break;
		case errOSAStackOverflow:
			theString = @"(errOSAStackOverflow) The runtime stack overflowed.";
			break;
		case errOSAInternalTableOverflow:
			theString = @"(errOSAInternalTableOverflow) A runtime internal data structure overflowed.";
			break;
		case errOSADataBlockTooLarge:
			theString = @"(errOSADataBlockTooLarge) An intrinsic limitation is exceeded for the size of a value or data structure.";
			break;
		case errOSACantGetTerminology:
			theString = @"(errOSACantGetTerminology) Can’t get the event dictionary.";
			break;
		case errOSACantCreate:
			theString = @"(errOSACantCreate) Can't make class <class identifier>.";
			break;
		case OSASyntaxError:
			theString = @"(OSASyntaxError) A syntax error occured.";
			break;
		case OSASyntaxTypeError:
			theString = @"(OSASyntaxTypeError) Another form of syntax was expected.";
			break;
		case OSATokenTooLong:
			theString = @"(OSATokenTooLong) A name or number is too long to be parsed.";
			break;
		case OSADuplicateParameter:
			theString = @"(OSADuplicateParameter) A formal parameter, local variable, or instance variable is specified more than once.";
			break;
		case OSADuplicateProperty:
			theString = @"(OSADuplicateProperty) A formal parameter, local variable, or instance variable is specified more than once.";
			break;
		case OSADuplicateHandler:
			theString = @"(OSADuplicateHandler) More than one handler is defined with the same name in a scope where the language doesn't allow it.";
			break;
		case OSAUndefinedVariable:
			theString = @"(OSAUndefinedVariable) A variable is accessed that has no value.";
			break;
		case OSAInconsistentDeclarations:
			theString = @"(OSAInconsistentDeclarations) A variable is declared inconsistently in the same scope, such as both local and global.";
			break;
		case OSAControlFlowError:
			theString = @"(OSAControlFlowError) An illegal control flow occurs in an application. For example, there is no catcher for the throw, or there was a non-lexical loop exit.";
			break;
		case OSAIllegalAssign:
			theString = @"(OSAIllegalAssign) An object can never be set in a container";
			break;
		case errOSACantAssign:
			theString = @"(errOSACantAssign) An object cannot be set in a container.";
			break;
		default:
			theString = @"Unknown";
			break;
	}
	return theString;
}



