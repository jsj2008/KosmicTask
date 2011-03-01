//
//  MGSTaskSpecifierManager.m
//  Mother
//
//  Created by Jonathan on 18/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
// This class is perhaps over complicated.
// It was envisaged that a collection of actions would be retained along with a history.
// The actions however are in effect retained by the action tabviews.
// Keeping a centralised collection of currently selected actions has little advantage.
// At present only a history is retained.
//
//
#import "MGSMother.h"
#import "MGSTaskSpecifierManager.h"
#import "MGSTaskSpecifier.h"
#import "MGSPath.h"
#import "MGSNetClient.h"
#import "MGSScript.h"
#import "MGSResult.h"
#import "MGSPreferences.h"

const char MGSContextHistoryCapacity;

static MGSTaskSpecifierManager *_sharedController = nil;

@interface MGSTaskSpecifierManager(Private)
- (id)contentAsPlist;
- (void)setContentAsPlist:(id)plist;
- (id)newObjectWithPlist:(NSDictionary *)plist;
- (void)applyCapacityLimit:(NSInteger)limit;
@end

@implementation MGSTaskSpecifierManager

@synthesize keepHistory = _keepHistory;
@synthesize history = _history;
@synthesize delegate = _delegate;
#pragma mark -
#pragma mark Class Methods

+ (id)sharedController
{
	if (!_sharedController) {
		_sharedController = [[self alloc] init];
	}
	return _sharedController;
}

#pragma mark -
#pragma mark Instance Methods
- (id) init
{
	if ((self = [super init])) {
		[self setObjectClass:[MGSTaskSpecifier class]];	// add this class
		_keepHistory = NO;
		_isHistory = NO;
		_maxHistoryCount = 100;	// hard default
		
		// observe task history capacity default
		[[NSUserDefaultsController sharedUserDefaultsController]  
			 addObserver:self
			 forKeyPath:[@"values." stringByAppendingString:MGSTaskHistoryCapacity]
			 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionPrior
			 context:(void *)&MGSContextHistoryCapacity];
	}
	return self;
}

- (id) initAsHistory
{
	self = [self init];
	_isHistory = YES;
	return self;
}

/*
 
 - newTaskSpecForNetClient:script:
 
 */
- (id)newTaskSpecForNetClient:(MGSNetClient *)netClient script:(MGSScript *)script
{
	MGSTaskSpecifier *taskSpec = [[MGSTaskSpecifierManager sharedController] newObject];
	taskSpec.netClient = netClient;
	taskSpec.script = [script mutableDeepCopy];
	
	return taskSpec;
}

#pragma mark KVO 

/*
 
 observe value for key path
 
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	#pragma unused(keyPath)
	#pragma unused(object)
	#pragma unused(change)
	
	if (context == &MGSContextHistoryCapacity) {
		_maxHistoryCount = [[NSUserDefaults standardUserDefaults] integerForKey:MGSTaskHistoryCapacity];
		[self applyCapacityLimit:_maxHistoryCount];
	}
}
#pragma mark Content
/*
 
 add object
 
 */
- (void)addObject:(id)object
{
	NSAssert([object isKindOfClass:[_sharedController objectClass]], @"invalid object added to action specifier handler");
	[super addObject:object];	// add to content								
}

/*
 
 add copy of completed action
 
 */
- (void)addCompletedActionCopy:(MGSTaskSpecifier *)anAction withResult:(MGSResult *)result
{
	MGSTaskSpecifier *action = [anAction mutableDeepCopyAsExistingInstance];
	
	//
	// action and result reference each other
	// note that we are simply retaining the result here as:
	//
	// 1. we should only need 1 copy of the results
	// 2. won't be recylced.mutated
	// 3. data sets can be large
	//
	action.result = result;	
	result.action = action;
	
	[self addObject:action];
	[self setSelectedObjects:[NSArray arrayWithObject:action]];
}

/*
 
 insert object
 
 */
- (void)insertObject:(id)object atArrangedObjectIndex:(NSUInteger)idx
{
	// if this is a history then limit the content size
	if (_isHistory) {
		int historyCount = [[self content] count];
		if (historyCount == _maxHistoryCount) {
			[self applyCapacityLimit:_maxHistoryCount-1];
		}
	}

	if (_delegate && [_delegate respondsToSelector:@selector(actionSpecifierWillBeAdded)] ) {
		[_delegate actionSpecifierWillBeAdded];
	}
	
	// increment identifier
	[[self content] makeObjectsPerformSelector:@selector(incrementIdentifier)];	
	[super insertObject:object atArrangedObjectIndex:idx];
	
	if (_delegate && [_delegate respondsToSelector:@selector(actionSpecifierAdded:)] ) {
		[_delegate actionSpecifierAdded:object];
	}
}

/*
 
 clear content
 
 */
- (void)removeAllObjects
{
	[self removeObjects:[self arrangedObjects]];
}

#pragma mark Persistence
/*
 
 save to path
 
 */
- (BOOL)saveToPath:(NSString *)path
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	// delete file if exists
	BOOL fileExists = [fileManager fileExistsAtPath:path];
	if (fileExists) {
		NSError *error;
		if (![fileManager removeItemAtPath:path error:&error]) {
			MLog(DEBUGLOG, @"error removing old content file: %@", [error localizedDescription]);
			return NO;			
		}
	}
	
	// cannot save the content as xml as it is not a plist
	// could adopt the NSCoding protocol - but then cannot view contents.
	// plus NSNetService etc do not adopt NSCoding themselves
	// so manipulation of their properties would also be required.
	// so transform content into a plist
	id plist = [self contentAsPlist];
	
	// serialize the plist into XML
	NSString *error;
	NSData *xmlData = [NSPropertyListSerialization dataFromPropertyList:plist
																 format:NSPropertyListXMLFormat_v1_0
													   errorDescription:&error];
	if(!xmlData)
	{
		MLog(DEBUGLOG, @"error serializing content: %@", error);
		return NO;
	}
	
	if (![xmlData writeToFile:path atomically:YES]) {
		MLog(DEBUGLOG, @"error saving content: %@", error);
		return NO;
	}
	
	return YES;
}

/* 
 
 load from path
 
 */
- (BOOL)loadFromPath:(NSString *)path
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if (![fileManager fileExistsAtPath:path]) {
		return NO;
	}

	NSData *plistData;
	NSString *error;
	NSPropertyListFormat format;
	id plist;
	plistData = [NSData dataWithContentsOfFile:path];
	
	plist = [NSPropertyListSerialization propertyListFromData:plistData
											 mutabilityOption:NSPropertyListMutableContainersAndLeaves
													   format:&format
											 errorDescription:&error];
	if (!plist) {
		MLog(DEBUGLOG, @"error deserializing content: %@", error);
		return NO;
	}
	
	[self setContentAsPlist:plist];
	
	return YES;
}

#pragma mark Properties
/*
 
 history path
 
 */
- (NSString *)historyPath
{
	return [[MGSPath userApplicationSupportPath] stringByAppendingPathComponent:@"TaskHistory.plist"];
	
}

/*
 
 keep a history
 
 */
- (void)setKeepHistory:(BOOL)value
{
	_keepHistory = value;
	if (_keepHistory) {
		// keep another instance as the history
		_history = [[MGSTaskSpecifierManager alloc] initAsHistory];
	} else {
		_history = nil;
	}
}
@end

@implementation MGSTaskSpecifierManager(Private)

/*
 
 apply capacity limit
 
 */
- (void)applyCapacityLimit:(NSInteger)limit
{
	NSInteger historyCount = [[self content] count];
	NSInteger removalCount = historyCount - limit;
	NSInteger removed = 0;
	
	if (removalCount <= 0) {
		return;
	}
	
	// remove item with identifier matching history count
	// have to search as sinply removing firt/last item in content
	// seemed to depend on whether the collection had been sorted
	for (NSInteger i = historyCount-1; i>=0; i--) {
		MGSTaskSpecifier *action = [[self content] objectAtIndex:i];
		if (action.identifier >= limit) {
			[self removeObject:action];
			if (++removed >= removalCount) {
				break;
			}
		}
	}
}

// get content as a plist
- (id)contentAsPlist
{
	NSMutableArray *plist = [NSMutableArray arrayWithCapacity:2];
	
	@try {
		for (MGSTaskSpecifier *action in [self content]) {
			[plist addObject:[action minimalPlistRepresentation]];	// exception if nil
		}
	}
	@catch (NSException *e) {
		MLog(DEBUGLOG, @"exception name: %@ description: %@", [e name], [e reason]);
		return nil;
	}
	
	return plist;
}

// set content from plist
- (void)setContentAsPlist:(id)plist
{
	NSMutableArray *content = [NSMutableArray arrayWithCapacity:2];
	for (id item in plist) {
		MGSTaskSpecifier *action = [self newObjectWithPlist:item];
		if (action) {
			[content addObject:action];
		}
	}
	[self setContent:content];
}

- (id)newObjectWithPlist:(NSDictionary *)plist
{
	MGSTaskSpecifier *action = [[[self objectClass] alloc] initWithMinimalPlistRepresentation:plist];
	
	return action;
}

/*
 
 set nil value for key
 
 */
- (void)setNilValueForKey:(NSString *)key
{
	// if select null placeholder item in list then selectedIndex gets set to nil,
	// hence we end up here!
	if ([key isEqualToString:@"selectionIndex"]) {
		[self setValue:[NSNumber numberWithInteger:NSNotFound] forKeyPath:key];
	}
}
@end
