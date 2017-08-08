//
//  MGSScriptManager.m
//  Mother
//
//  Created by Jonathan on 08/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
// Note that this class subclasses MGSArray
// as such it can operate in two modes
// 1. as a wrapper to a script dictionary -useFactorySelector:YES
// 2. as an array of script objects -useFactorySelector:NO
//
// See notes to MGSArray
//
#import "MGSMother.h"
#import "MGSScriptManager.h"
#import "MGSScriptPlist.h"
#import "MGSScript.h"
#import "NSMutableDictionary_Mugginsoft.h"
#import "MGSPath.h"
#import "NSString_Mugginsoft.h"
#import "MGSImageAndText.h"
#import "MGSImageAndTextCell.h"

@interface MGSScriptManager (Private)
- (void)updateDisplayObject;
@end


@implementation MGSScriptManager

@synthesize name = _name;
@synthesize hasScripts = _hasScripts;
@synthesize hasAllScripts = _hasAllScripts;
@synthesize groupCount = _groupCount;

#pragma mark Class Methods

/* 
 
 path to user scripts document folder
 
 */
+ (NSString *)userDocumentPath
{
	return [MGSPath userDocumentPath];
}


/* 
 
 path to bundle scripts document folder
 
 this code is called both by the client and by the agent tool.
 
 */
+ (NSString *)bundleDocumentPath
{
    NSString *path = [MGSPath bundleResourcePath];
    
	// regardless of where the agent tool is in the app bundle the plists are in the bundle resources folder
	path = [path stringByAppendingPathComponent:@"Tasks"];
	path = [path stringByStandardizingPath];
	
	// validate
	BOOL isDir = YES;
	if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir) {
		MLog(DEBUGLOG, @"tasks path is: %@", path);
	} else {
		MLog(RELEASELOG, @"invalid tasks path at: %@", path);
		path = nil; 
	}
	
	return path;
}

/*
 
 path to application scripts document folder
 
 */
+ (NSString *)applicationDocumentPath
{
	NSString *path = nil;
	
	// use external folder for application scripts
	if (YES) {
		path = [MGSPath verifyApplicationDocumentPath];
	} else {
		
		// there is nothing wrong with retrieving the scripts from the bundle.
		// the only problem is that they cannot be indexed on 10.6
		path = [self bundleDocumentPath];
	}
	
	return path;
}

#pragma mark Instance Methods
/*
 
 init
 
 when access the array items will be returned as script objects even though they are stored as dictionaries
 
 */
- (id)init
{
	// must initialise super with class and factory selector used to wrap around array items
	if ((self = [super initWithItemClass:[MGSScript class] 
					withFactorySelector:@selector(dictWithDict:) 
					withAddItemSelector:@selector(dict)])) {
		self.hasScripts = NO;
		self.hasAllScripts = NO;
		self.groupCount = 0;
		_imageAndText = [[MGSImageAndText alloc] init];
		_imageAndText.hasCount = YES;

	}
	return self;
}

/*
 
 init for script objects
 
 the array contains script refs not dictionaries
 
 */
- (id)initForScriptObjects
{
	if (!(self = [self init])) return nil;
	[self setArray:[NSMutableArray arrayWithCapacity:2]];
	self.useFactorySelector = NO;
	return self;
}


/*
 
 published script handler
 
 */
- (id)publishedScriptManager
{
	// make copy that contains contains only published members
	NSMutableArray *scriptArray = [NSKeyedUnarchiver unarchiveObjectWithData: [NSKeyedArchiver archivedDataWithRootObject: [self array]]];
	id scriptManager = [[[self class] alloc] init];
	[scriptManager setArray:scriptArray];
	[scriptManager removeUnpublishedItems];
	
	return scriptManager;
}




/*
 
 set has all scripts
 
 */
- (void)setHasAllScripts:(BOOL)value
{
	_hasAllScripts = value;
	[self updateDisplayObject];
}
/*
 
 set array
 
 */
- (void)setArray:(NSMutableArray *)array 
{
	[super setArray:array];
	self.hasScripts =  (array && [array count] > 0) ? YES : NO;
}

/*
 
 sort the array
 
 */
- (void)sortUsingDescriptors:(NSArray *)descriptors
{
	[[self array] sortUsingDescriptors:descriptors];
}

#pragma mark Collections 
/*
 
 dictionary
 
 even though MGSScriptManaer is an array subclass it is normally represented as a dictionary.
 at present the dictionary only contains 1 key, the array of scripts
 
 */
- (NSMutableDictionary *)dictionary 
{
	// build dictionary representing this object
	return [NSMutableDictionary dictionaryWithObjectsAndKeys:[self array], MGSScriptKeyScripts, nil];
}
/*
 
 set dictionary
 
 */
- (void)setDictionary:(NSMutableDictionary *)dict
{
	// load array from dict with key MGSScriptKeyScripts
	id array = [dict objectForKey:MGSScriptKeyScripts];
	if (nil == array || NO == [array isKindOfClass:[NSArray class]]) {
		[self setArray:nil];
		return;
	}
	
	[self setArray:array];
}

/*
 
 deep copy of dictionary
 
 contents of NSMutableDictionary must conform to NSCoding
 
 */
- (NSMutableDictionary *)mutableDeepCopyOfDictionary
{
	return [NSKeyedUnarchiver unarchiveObjectWithData: [NSKeyedArchiver archivedDataWithRootObject: [self dictionary]]];
}

/*
 
 create a dict copy of the changed items in the dictionary 
 
 */
- (NSMutableDictionary *)changeDictionaryCopy
{
	return [NSMutableDictionary dictionaryWithObject:[self changeArrayCopy] forKey:MGSScriptKeyScripts];;
}
/*
 
 create an array copy of the changed items in the dictionary 
 
 */
- (NSMutableArray *)changeArrayCopy
{
	NSMutableArray *editArray = [NSMutableArray arrayWithCapacity:2];
	
	// create array of edited scripts
	for (NSInteger i = [self count] - 1; i >= 0; i--) {
		MGSScript *script = [self itemAtIndex:i];
		
		// we want:
		// 1. scripts scheduled for delete
		// 2. script scheduled for publish
		if ([script scheduleDelete] || [script schedulePublished]) {
			[editArray addObject:[[script mutableDeepCopy] dict]];
		}
	}
	
	return editArray;
}

/*
 
 - changeArrayScheduleForDelete
 
 */
- (NSArray *)changeArrayScheduleForDelete
{
	NSMutableArray *editArray = [NSMutableArray arrayWithCapacity:2];
	
	// create array of edited scripts
	for (NSInteger i = [self count] - 1; i >= 0; i--) {
		MGSScript *script = [self itemAtIndex:i];
		
		// we want:
		// 1. scripts scheduled for delete
		if ([script scheduleDelete]) {
			[editArray addObject:script];
		}
	}
	
	return editArray;
}

/*
 
 dictionary containing edit info for script
 
 */
- (NSMutableDictionary *)editDictionaryForScript:(MGSScript *)script
{
	return [self editDictionaryForScripts:[NSArray arrayWithObject:script]];
}

/*
 
 dictionary containing edit info for scripts array
 
 */
- (NSMutableDictionary *)editDictionaryForScripts:(NSArray *)scripts
{
	NSMutableArray *editArray = [NSMutableArray arrayWithCapacity:2];
	
	// create array of edited scripts
	for (MGSScript *script in scripts) {
		
		// we only wanted scripts scheduled for save
		if ([script scheduleSave]) {
			
			NSMutableDictionary *dictCopy = [[script mutableDeepCopy] dict];
			[editArray addObject:dictCopy];
			
			// accept the schedule for save
			[script acceptScheduleSave];
		}
	}
	
	// sanity check. we do not want to initiate an empty save
	if ([editArray count] == 0) {
		return nil;
	}
	
	return [NSMutableDictionary dictionaryWithObject:editArray forKey:MGSScriptKeyScripts];
}

/*
 
 create a copy of the edited items in the dictionary 
 
 */
- (NSMutableDictionary *)editDictionaryCopy
{
	NSMutableArray *editArray = [NSMutableArray arrayWithCapacity:2];
	
	// create array of edited scripts
	NSInteger i;
	for (i = [self count] - 1; i >= 0; i--) {
		MGSScript *script = [self itemAtIndex:i];
		
		// we only wanted scripts scheduled for save
		if ([script scheduleSave]) {
			NSMutableDictionary *dictCopy = [[script mutableDeepCopy] dict];
			[editArray addObject:dictCopy];
			
			// accept the schedule for save
			[script acceptScheduleSave];
		}
	}

	return [NSMutableDictionary dictionaryWithObject:editArray forKey:MGSScriptKeyScripts];
}

/*
 
 scripts dictionary
 
 a dictionary of all the handler script keys
 
 */
- (NSDictionary *)scriptDictionaryWithUUIDKeys
{
	NSMutableDictionary *mutableDict = [NSMutableDictionary dictionaryWithCapacity:1];
	for (int i = 0;i < [self count]; i++) {
		MGSScript *script = [self itemAtIndex:i];
		[mutableDict setObject:script forKey:[script UUID]];
	}
	
	return [NSDictionary dictionaryWithDictionary:mutableDict];
}

#pragma mark Display 
/*
 
 set name
 
 */
- (void)setName:(NSString *)name
{
	_name = name;
	[self updateDisplayObject];
}

/*
 
 display name
 
 */

- (NSString *)displayName
{
	if (self.hasAllScripts) {
		return [NSString stringWithFormat:NSLocalizedString(@"%@ (%d Groups)", @"All group table view column format - display name"), _name, self.groupCount];
	} else {
		return [NSString stringWithFormat:NSLocalizedString(@"%@", @"Group table view column format - display name"), _name];
	}
}
/*
 
 display object
 
 */
- (MGSImageAndText *)displayObject
{
	_imageAndText.value = self.displayName;
	_imageAndText.count = self.count;
	
	return _imageAndText;
}

/*
 
 set display image
 
 */
- (void)setDisplayImage:(NSImage *)image
{
	_imageAndText.image = image;
}

#pragma mark Modification
/*
 
 remove the scriptcode from the scripts
 
 */
- (void)removeScriptCode
{
	for (NSInteger i = [self count] - 1; i >= 0; i--) {
		MGSScript *script = [self itemAtIndex:i];
		[script removeScriptCode];
	}
}

/* 
 
 remove script
 
 */
- (void)removeScript:(MGSScript *)script
{
	if ([self useFactorySelector]) {
		[[self array] removeObject:[script dict]];
	} else {
		[[self array] removeObject:script];
	}
}

/*
 
 set script status
 
 */
- (void)setScriptStatus:(MGSScriptStatus)status
{
	NSInteger i;
	for (i = [self count] - 1; i >= 0; i--) {
		MGSScript *script = [self itemAtIndex:i];
		[script setScriptStatus: status];
	}
}

/*
 
 remove unpublished items
 
 */
- (void)removeUnpublishedItems
{
	for (NSInteger i = [self count] - 1; i >= 0; i--) {
		MGSScript *script = [self itemAtIndex:i];
		if (![script published]) {
			[self removeItemAtIndex:i];
		}
	}
}

#pragma mark Published 
/*
 
 published count
 
 */
- (NSInteger)publishedCount
{
	int i, publishedCount = 0;
	for (i = 0;i < [self count]; i++) {
		MGSScript *script = [self itemAtIndex:i];
		if ([script published] && [script isValidGroupMember]) {
			publishedCount++;
		}
	}
	
	return publishedCount;
}

/*
 
 published state
 
 */
- (NSCellStateValue)publishedCellState
{
	NSInteger publishedCount = [self publishedCount];
	
	if ([self count] == publishedCount) {
		return NSOnState;
	} else if (publishedCount > 0) {
		return NSMixedState;
	} else {
		return NSOffState;
	}
}



#pragma mark Schedule Save
/*
 
 accept schedule save 
 
 */
- (void)acceptScheduleSave
{
	
	NSInteger i;
	for (i = [self count] - 1; i >= 0; i--) {
		MGSScript *script = [self itemAtIndex:i];
		
		// we only wanted scripts scheduled for save
		if ([script scheduleSave]) {
			[script acceptScheduleSave];
		}
	}	
}

#pragma mark Schedule Delete 
/*
 
 undo schedule delete
 
 */
- (void)undoScheduleDelete
{
	
	NSInteger i;
	for (i = [self count] - 1; i >= 0; i--) {
		MGSScript *script = [self itemAtIndex:i];
		
		// if scheduled for delete
		if ([script scheduleDelete]) {			
			[script undoScheduleDelete];
		}
	}	
}
/*
 
 accept schedule delete
 
 */
- (void)acceptScheduleDelete
{
	NSInteger i;
	for (i = [self count] - 1; i >= 0; i--) {
		MGSScript *script = [self itemAtIndex:i];
		
		// we only wanted scripts scheduled for delete
		if ([script scheduleDelete]) {
			[self removeItemAtIndex:i];
		}
	}	
}


#pragma mark Schedule Published
/*
 
 set schedule published
 
 note that confusion may reign here due to the fact that our array may contain dictionaries OR script objects.
 for (id script in [self array]) {} will only work if the array contains script objects.
 for (i = [self count] - 1; i >= 0; i--) {}  will work for everything
 
 */
- (void)setSchedulePublished:(BOOL)value
{
	for (int i = 0; i < [self count]; i++) {
		MGSScript *script = [self itemAtIndex:i];
		[script setSchedulePublished:value];
	}
}

/*
 
 accept schedule for publish 
 
 */
- (void)acceptSchedulePublished
{
	
	NSInteger i;
	for (i = [self count] - 1; i >= 0; i--) {
		MGSScript *script = [self itemAtIndex:i];
		
		// if scheduled for publish
		if ([script schedulePublished]) {
			[script acceptSchedulePublished];
		}
	}	
}

/*
 
 undo schedule published
 
 */
- (void)undoSchedulePublished
{
	
	NSInteger i;
	for (i = [self count] - 1; i >= 0; i--) {
		MGSScript *script = [self itemAtIndex:i];
		
		// if scheduled for publish then undo
		if ([script schedulePublished]) {
			[script undoSchedulePublished];
		}
	}	
}

@end

@implementation MGSScriptManager (Private)

/*
 
 update display object
 
 */

- (void)updateDisplayObject
{
	if (self.hasAllScripts) {
		_imageAndText.countColor = [MGSImageAndTextCell countColorGreen];
	} else {
		_imageAndText.countColor = [MGSImageAndTextCell countColor];
	}	
}
@end
