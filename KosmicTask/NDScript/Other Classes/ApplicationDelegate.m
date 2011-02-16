#import "ApplicationDelegate.h"
#import "BaseTestClass.h"
#import "LoggingObject.h"
#import "NSString+NDUtilities.h"

static NSString					* kTestClassListFile = @"TestClasses";
static const NSTimeInterval		kTestFrequency = 0.001;

@implementation ApplicationDelegate

- (id)init
{
	if( (self = [super init]) != nil )
	{
		commandKeyTest = YES;
		stopRepeat = YES;
	}
	return self;
}

/*
 * -awakeFromNib
 */
- (void)awakeFromNib
{
#ifdef __OBJC_GC__
	[garbageCollectionEnabledField setStringValue:@"Garbage Collection Enabled"];
	[garbageCollectionEnabledField setTextColor:[NSColor darkGrayColor]];
#else
	[garbageCollectionEnabledField setStringValue:@"Garbage Collection Disabled"];
	[garbageCollectionEnabledField setTextColor:[NSColor grayColor]];
#endif
	[self createTests];
}

#ifndef __OBJC_GC__
- (void)dealloc
{
	[testObjects release];
	[loggingObject release];
	[super dealloc];
}
#endif
/*
 * -createTests
 */
- (void)createTests
{
	NSString			* thePathsString = [[NSBundle mainBundle] pathForResource:kTestClassListFile ofType:@"plist"];
	NSArray				* theTestsArray = [NSArray arrayWithContentsOfFile:thePathsString];
	unsigned int		theIndex = 0,
						theCount = theTestsArray ? [theTestsArray count] : 0;

	for( theIndex = 0; theIndex < theCount; theIndex++ )
	{
		NSDictionary				* theDict = [theTestsArray objectAtIndex:theIndex];
		BaseTestClass				* theInstance;
		
		if( [[theDict objectForKey:@"Separator"] boolValue] == NO)
		{
			NSString				* theClassName = [theDict objectForKey:@"ClassName"],
									* theTestName = [theDict objectForKey:@"TestName"];
			theInstance = [[NSClassFromString(theClassName) alloc] initWithLoggingObject:[self loggingObject]];
			
			NSAssert2( theInstance != nil, @"Reciever nil test named '%@'	class %@", theTestName, theClassName );
			[self addTest:theInstance withNamed:theTestName selected:[[theDict objectForKey:@"RunSelected"] boolValue]];
			[theInstance release];
		}
		else
			[self addSeparatorName:[theDict objectForKey:@"TestName"]];
	}
}

/*
 * -runTests:
 */
- (IBAction)runTests:(id)aSender
{
	if( stopRepeat )
	{
		runCount = [repeatButton state] == NSOnState
						? [repeatValueField intValue]
						: 1;
		[self resetErrorCount];
		repeatCount = 0;
		testNumber = 0;
		
		[self enableRunButton:NO];
		stopRepeat = NO;
		[NSTimer scheduledTimerWithTimeInterval:0.0
										 target:self
									   selector:@selector(runTestEntry:)
									   userInfo:nil
										repeats:NO]; 
	}
	else
	{
		[self enableRunButton:YES];
		stopRepeat = YES;
	}
}

/*
 * -runTestEntry:
 */
- (void)runTestEntry:(NSTimer *)aTimer
{
	int			theCount = [testCheckBoxMatrix numberOfRows];
	
	if( !stopRepeat && repeatCount < runCount )
	{
		NSCell		* theCell = [testCheckBoxMatrix cellAtRow:testNumber column:0];
		if( testNumber == 0 )
			[self setRunningTestCount:repeatCount outOfTotal:runCount];
		
		if( [theCell state] == NSOnState )
		{
			NSString		* theTestName = [theCell title];
			[self logMessage:[NSString stringWithFormat:@"start:\t\t\"%@\"", theTestName] withColor:[NSColor colorWithDeviceRed:0.0 green:0.90 blue:0.0 alpha:1.0]];
			[self setRunningTestName:theTestName];
			[self runTestNamed:theTestName];
		}
		else
		{
			[NSTimer scheduledTimerWithTimeInterval:0.001
											 target:[[NSApplication sharedApplication] delegate]
										   selector:@selector(runTestEntry:)
										   userInfo:nil
											repeats:NO];
		}
		
		testNumber++;
		
		if( testNumber > theCount )
		{
			testNumber = 0;
			repeatCount++;
		}
	}
	else
	{
		[self setRunningTestName:nil];
		[self setRunningTestCount:0 outOfTotal:0];
		[self enableRunButton:YES];
		stopRepeat = YES;
	}
}

- (void)finishedTest:(id)ignored
{
	[self logMessage:[NSString stringWithFormat:@"end"]
		   withColor:[NSColor colorWithDeviceRed:0.0
										   green:0.90
											blue:0.0
										   alpha:1.0]];
	[NSTimer scheduledTimerWithTimeInterval:0.0001
									 target:[[NSApplication sharedApplication] delegate]
								   selector:@selector(runTestEntry:)
								   userInfo:nil
									repeats:NO];
}

/*
 * -clearLogs:
 */
- (IBAction)clearLogs:(id)aSender
{
	[logTextView setString:@""];
	[clearButton setEnabled:NO];
}

- (IBAction)clearNumberOfScriptLoggins:(id)aSender
{
	[[self loggingObject] resetNumberOfScriptLoggings];
	[numberOfScriptLoggingButton setTitle:[NSString stringWithFormat:@"%d", [[self loggingObject] numberOfScriptLoggings]]];
}

/*
 * -selectAll:
 */
- (IBAction)selectAll:(id)aSender
{
	int		theIndex,
				theCount = [testCheckBoxMatrix numberOfRows];
	for( theIndex = 0; theIndex < theCount; theIndex++ )
		[testCheckBoxMatrix setState:NSOnState atRow:theIndex column:0];
	[self selectedTestChanged:aSender];
	[runButton setEnabled:YES];
	[deselectAllButton setEnabled:YES];
}

/*
 * -deselectAll:
 */
- (IBAction)deselectAll:(id)aSender
{
	int		theIndex,
	theCount = [testCheckBoxMatrix numberOfRows];
	for( theIndex = 0; theIndex < theCount; theIndex++ )
		[testCheckBoxMatrix setState:NSOffState atRow:theIndex column:0];
	[self selectedTestChanged:aSender];
 	[runButton setEnabled:NO];
	[selectAllButton setEnabled:YES];
}

/*
 * -selectedTestChanged:
 */
- (IBAction)selectedTestChanged:(id)aSender
{
	int		theIndex,
				theSelectedCount = 0,
				theCount = [testCheckBoxMatrix numberOfRows];

	for( theIndex = 0; theIndex < theCount; theIndex++ )
	{
		if( [[testCheckBoxMatrix cellAtRow:theIndex column:0] state] == NSOnState )
			theSelectedCount++;
	}
	
	[deselectAllButton setEnabled:theSelectedCount != 0];
	[selectAllButton setEnabled:theSelectedCount != theCount];
	[runButton setEnabled:theSelectedCount != 0];
}

/*
 * -repeatChanged:
 */
- (IBAction)repeatChanged:(id)aSender
{
	[repeatValueField setEnabled:[aSender state] == NSOnState ? YES : NO];	
}

/*
 * -runTestNamed:
 */
- (BOOL)runTestNamed:(NSString *)aName
{
	BaseTestClass	* theTest = [testObjects objectForKey:aName];
	NSParameterAssert( aName != nil );
	if( theTest != nil )
	{
		[theTest run];
	}
	return theTest != nil;
}

- (void)enableRunButton:(BOOL)anEnable
{
	if( anEnable )
	{
		[runButton setTitle:@"Run"];
		[runButton setKeyEquivalent:@"R"];
		[runButton setKeyEquivalentModifierMask:NSCommandKeyMask];
	}
	else
	{
		[runButton setTitle:@"Stop"];
		[runButton setKeyEquivalent:@"."];
		[runButton setKeyEquivalentModifierMask:NSCommandKeyMask];
	}
}

/*
 * -addSeparatorName:
 */
- (void)addSeparatorName:(NSString *)aName
{
	int				theIndex = 0;
	NSRect			theFrame = NSMakeRect( 0, 0, 0, 0 ),
					theNewFrame = NSMakeRect( 0, 0, 0, 0 );
	NSButtonCell	* theCell = nil;

	commandKeyTest = NO;

	NSLog( @"Adding seperator named %@", aName ? aName : @"unamed" );
	
	if( testObjects == nil )
		testObjects = [[NSMutableDictionary alloc] init];
	else
	{
		theIndex = [testCheckBoxMatrix numberOfRows];
		[testCheckBoxMatrix addRow];
	}
	
	theCell = [testCheckBoxMatrix cellAtRow:theIndex column:0];
	
	[theCell setTitle:aName ? aName : @""];
	[theCell setEnabled:NO];
	[theCell setTransparent:YES];

	theFrame = [testCheckBoxMatrix frame];
	[testCheckBoxMatrix sizeToFit];
	theNewFrame = [testCheckBoxMatrix frame];
	[testCheckBoxMatrix setFrame:NSMakeRect(NSMinX(theFrame), NSMaxY(theFrame) - NSHeight(theNewFrame), NSWidth(theFrame), NSHeight(theNewFrame) )];
}

/*
 * -addTest:withNamed:selected:
 */
- (BOOL)addTest:(BaseTestClass *)aTest withNamed:(NSString *)aName selected:(BOOL)aSelected
{
	int		theIndex = 0;
	BOOL		theResult = NO;
	NSParameterAssert( aName != nil );
	
	if( [testObjects objectForKey:aName] == nil )
	{
		NSRect			theFrame = NSMakeRect( 0, 0, 0, 0 ),
						theNewFrame = NSMakeRect( 0, 0, 0, 0 );
		NSButtonCell	* theCell = nil;
		NSLog( @"Adding test named %@, %s", aName, aSelected ? "selected" : "unselected" );

		if( testObjects == nil )
			testObjects = [[NSMutableDictionary alloc] init];
		else
		{
			theIndex = [testCheckBoxMatrix numberOfRows];
			[testCheckBoxMatrix addRow];
		}
		
		[testObjects setObject:aTest forKey:aName];
		
		theCell = [testCheckBoxMatrix cellAtRow:theIndex column:0];

		[theCell setTitle:aName];
		[theCell setState:aSelected ? NSOnState : NSOffState];
		if( commandKeyTest && theIndex < 10 )
		{
			[theCell setKeyEquivalent:[NSString stringWithFormat:@"%u",(theIndex+1)%10]];
			[testCheckBoxMatrix setToolTip:[NSString stringWithFormat:@"Command Key %u",(theIndex+1)%10] forCell:theCell];
			[theCell setKeyEquivalentModifierMask:NSCommandKeyMask];
		}
		theFrame = [testCheckBoxMatrix frame];
		[testCheckBoxMatrix sizeToFit];
		theNewFrame = [testCheckBoxMatrix frame];
		[testCheckBoxMatrix setFrame:NSMakeRect(NSMinX(theFrame), NSMaxY(theFrame) - NSHeight(theNewFrame), NSWidth(theFrame), NSHeight(theNewFrame) )];
		theResult = YES;
	}
	else
		NSLog( @"Already have a test titled \"%@\"", aName );
	return theResult;
}

/*
 * -logMessage:
 */
- (void)logMessage:(NSString *)aString
{
	aString = [aString prepareForLoggingObject];
	[self logMessage:[NSString stringWithFormat:@"log:\t\t%@", aString] withColor:[NSColor darkGrayColor]];
}

/*
 * -errorMessage:
 */
- (void)errorMessage:(NSString *)aString
{
	aString = [aString prepareForLoggingObject];
	[self logMessage:[NSString stringWithFormat:@"error:\t%@", aString] withColor:[NSColor redColor]];
	[self increamentErrorCount];
}

/*
 * -logScriptMessage:
 */
- (void)logScriptMessage:(NSString *)aString
{
	[self logMessage:aString withColor:[NSColor blueColor]];
}

/*
 * -logMessage:withColor:
 */
- (void)logMessage:(NSString *)aString withColor:(NSColor *)aColor
{
	NSString		* theString = [aString stringByAppendingString:@"\n"];
	unsigned int	theInitialLen = [[logTextView string] length]; 
	NSRange			theRange = NSMakeRange(theInitialLen, 0 );
	NSParameterAssert( theString != nil );
	[logTextView replaceCharactersInRange:theRange withString:theString];
	theRange.length = [[logTextView string] length] - theInitialLen;
	[logTextView setTextColor:aColor range:theRange];
	[logTextView scrollRangeToVisible:theRange];
	[logTextView scrollPageDown:nil];
	[logTextView display];
	[clearButton setEnabled:YES];
	[numberOfScriptLoggingButton setTitle:[NSString stringWithFormat:@"%d", [[self loggingObject] numberOfScriptLoggings]]];
}

/*
 * -logContent
 */
- (NSString *)logContent
{
	return [logTextView string];
}

/*
 * -loggingObject
 */
- (LoggingObject *)loggingObject
{
	if( loggingObject == nil )
		loggingObject = [[LoggingObject alloc] initWithDelegate:self];
	NSParameterAssert( loggingObject != nil );
	return loggingObject;
}

/*
 * -setRunningTestName:
 */
- (void)setRunningTestName:(NSString *)aName
{
	[runningTestNameField setStringValue:aName ? [NSString stringWithFormat:@"Running Test \"%@\"",aName] : @""];
	[runningTestNameField display];
}

/*
 * -setRunningTestCount:outOfTotal:
 */
- (void)setRunningTestCount:(unsigned int)anIndex outOfTotal:(unsigned int)aCount
{
	if( [repeatButton state] == NSOnState && aCount > 0 )
		[runningTestCountField setStringValue:[NSString stringWithFormat:@"%u of %u", anIndex+1, aCount]];
	else
		[runningTestCountField setStringValue:@""];
	[runningTestCountField display];
}

/*
 * -increamentErrorCount
 */
- (void)increamentErrorCount
{
	if( errorCount < 10000 )
	{
		errorCount++;
		[errorCountField setStringValue:[NSString stringWithFormat:@"errors: %5u", errorCount]];
	}
	else
		[errorCountField setStringValue:@"errors: 10000+"];
	[errorCountField display];
}

/*
 * -resetErrorCount
 */
- (void)resetErrorCount
{
	errorCount = 0;
	[errorCountField setStringValue:@""];
	[errorCountField display];
}


@end
