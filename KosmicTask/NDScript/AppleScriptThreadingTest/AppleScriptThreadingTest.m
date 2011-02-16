#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>

const unsigned int		kNumberOfThreads = 10,
								kNumberOfLoops = 1000;
@interface ScriptData : NSObject
{
	unsigned int			number;
	ComponentInstance		scriptingComponent;
	OSAID						scriptID;
}
- (id)initWithUnsingedInt:(unsigned int)aNumber;
- (void)run;
- (void)threadEntry:(id)anObject;
+ (void)waitForScriptsToEnd;
@end

int main (int argc, const char * argv[])
{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	NSMutableArray			* theScriptsArray = [NSMutableArray array];
	unsigned int			theIndex;
	
	for( theIndex = 0; theIndex < kNumberOfThreads; theIndex++ )
		[theScriptsArray addObject:[[ScriptData alloc] initWithUnsingedInt:theIndex + 1]];
	
	[theScriptsArray makeObjectsPerformSelector:@selector(run)];
	
	[ScriptData waitForScriptsToEnd];
	
	[pool release];
	return 0;
}

@implementation ScriptData

static NSConditionLock		* waitLock = nil;

- (id)initWithUnsingedInt:(unsigned int)aNumber
{
	if( (self = [self init]) != nil )
	{
		if( (scriptingComponent = OpenDefaultComponent( kOSAComponentType, kAppleScriptSubtype )) != NULL )
		{
			NSAppleEventDescriptor		* theSource = [NSAppleEventDescriptor descriptorWithString:[NSString stringWithFormat:@"tell application \"NDScriptTestReceiver\"\n\trepeat 20 times\n\t\tdisplay logging message \"i=%u\"\n\tend repeat\nend tell\n", aNumber]];
			number = aNumber;
			scriptID = kOSANullScript;
			if( OSACompile( scriptingComponent,
							[theSource aeDesc],
							kOSAModeCanInteract | kOSAModeCantSwitchLayer | kOSAModeCompileIntoContext,
							&scriptID
							) != noErr )
			{
				NSLog( @"Failed to compile script" );
				[self release];
				self = nil;
			}
		}
		else
		{
			NSLog( @"Failed to open default component" );
			[self release];
			self = nil;
		}
	}
	return self;
}

- (void)dealloc
{
	if( OSADispose( scriptingComponent, scriptID ) != noErr )
		NSLog( @"Failed to dispose script" );
	
	[super dealloc];
}

- (void)run
{
	if( waitLock == nil )
	{
		waitLock = [[NSConditionLock alloc] initWithCondition:1];
	}
	else
	{
		[waitLock lock];
		[waitLock unlockWithCondition:[waitLock condition]+1];
	}
	
	[NSThread detachNewThreadSelector:@selector(threadEntry:) toTarget:self withObject:nil];
}

- (void)threadEntry:(id)anObject
{
	unsigned int		theIndex;
	for( theIndex = 0; theIndex < kNumberOfLoops; theIndex++ )
	{
		OSAID		theResult;
		if( number == 0 && (theIndex+1)%100 == 0 )
			NSLog( @"Count = %u", theIndex );

		if( OSAExecute( scriptingComponent, scriptID, kOSANullScript, kOSAModeCanInteract | kOSAModeCantSwitchLayer,  &theResult
							 ) != noErr )
			NSLog( @"Failed to execute script" );
	}

	[waitLock lock];
	[waitLock unlockWithCondition:[waitLock condition]-1];
}

+ (void)waitForScriptsToEnd
{
	[waitLock lockWhenCondition:0];
	[waitLock unlock];
}

@end
