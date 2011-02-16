//
//  MGSScriptGroup.m
//  Mother
//
//  Created by Jonathan on 16/11/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSScriptGroup.h"
#import "MGSResourceImages.h"

#define DEFAULT_ALL_GROUP_IMAGE_NAME @"44.png"
#define DEFAULT_GROUP_IMAGE_NAME @"47.png"

//#define DEFAULT_ALL_GROUP_IMAGE_NAME @"105.png"
//#define DEFAULT_GROUP_IMAGE_NAME @"99.png"

NSString *MGSKeyGroup = @"Group";
NSString *MGSKeyAllGroup = @"AllGroup";
NSString *MGSKeyGroups = @"Groups";

static NSMutableArray *_groupResourceIcons = nil;

@implementation MGSScriptGroup

/*
 
 init
 
 */
- (id)init
{
	return [self initWithContentsOfFile:nil];
}
/*
 
 init with contents of file
 
 */
- (id)initWithContentsOfFile:(NSString *)path
{
	if ((self = [super init])) {
		
		// load group dict from path
		if (path) {
			_groupDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:path];
		}
		if (!_groupDictionary) {
			_groupDictionary = [NSMutableDictionary dictionaryWithCapacity:1];
			
		}

		// validate the dictionary
		NSMutableDictionary *groups = [_groupDictionary objectForKey:MGSKeyGroups];
		if (!groups) {
			groups = [NSMutableDictionary dictionaryWithCapacity:2];
			[_groupDictionary setObject:groups forKey:MGSKeyGroups];
		}
		
	}
	
	return self;
}

/*
 
 save to path
 
 */
- (BOOL)saveToPath:(NSString *)path
{
	return [_groupDictionary writeToFile:path atomically:YES];
}
/*
 
 group resource icons
 
 */
- (NSMutableArray *)groupResourceIcons
{
	// lazy
	if (!_groupResourceIcons) {
		// local group icons dict array
		NSString *groupIconsPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"GroupIcons"];
		_groupResourceIcons = [MGSResourceImages imageDictionaryArrayAtPath:groupIconsPath];
	}
	
	return _groupResourceIcons;
}


/*
 
 image for group name
 
 */
- (NSImage *)imageForGroupName:(NSString *)name
{
	NSString *imageName = nil, *location = nil;
	[self imageResourceForGroupName:name imageName:&imageName location:&location];
	return [self imageForName:imageName location:location];
}

/*
 
 image resource for group name
 
 */
- (void)imageResourceForGroupName:(NSString *)groupName imageName:(NSString **)imageName location:(NSString **)location
{
	// search groups for group name
	NSDictionary *groups = [_groupDictionary objectForKey:MGSKeyGroups];
	if (!groups) return;
	NSDictionary *group = [groups objectForKey:groupName];
	if (group) {
		*imageName = [group objectForKey:MGSImageCollectionKeyName];
		*location = [group objectForKey:MGSImageCollectionKeyLocation];
	}
	
}

/*
 
 image resource for all group
 
 */
- (void)imageResourceForAllGroup:(NSString **)imageName location:(NSString **)location
{
	NSDictionary *group = [_groupDictionary objectForKey:MGSKeyAllGroup];
	if (group) {
		*imageName = [group objectForKey:MGSImageCollectionKeyName];
		*location = [group objectForKey:MGSImageCollectionKeyLocation];
	}
}

/*
 
 image resource for group
 
 */
- (void)imageResourceForGroup:(NSString **)imageName location:(NSString **)location
{
	NSDictionary *group = [_groupDictionary objectForKey:MGSKeyGroup];
	if (group) {
		*imageName = [group objectForKey:MGSImageCollectionKeyName];
		*location = [group objectForKey:MGSImageCollectionKeyLocation];
	} 
}
/*
 
 image for group 
 
 this will provide a default group image
 
 */
- (NSImage *)imageForGroup
{
	NSString *imageName = nil, *location = nil;
	[self imageResourceForGroup:&imageName location:&location];
	return [self imageForName:imageName location:location];
}

/*
 
 set image resource for group 
 
 */
- (void)setImageResourceForGroupName:(NSString *)groupName imageName:(NSString *)imageName location:(NSString *)location
{
	// search groups for group name
	NSMutableDictionary *groups = [_groupDictionary objectForKey:MGSKeyGroups];
	if (!groups) return;
	
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys: imageName, MGSImageCollectionKeyName, location, MGSImageCollectionKeyLocation, nil];
	[groups setObject:dict forKey:groupName];
}

/*
 
 set image resource for allgroup 
 
 */
- (void)setImageResourceForAllGroup:(NSString *)imageName location:(NSString *)location
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys: imageName, MGSImageCollectionKeyName, location, MGSImageCollectionKeyLocation, nil];
	[_groupDictionary setObject:dict forKey:MGSKeyAllGroup];
}
/*
 
 image for all group 
 
 */
- (NSImage *)imageForAllGroup
{
	NSString *imageName = nil, *location = nil;
	[self imageResourceForAllGroup:&imageName location:&location];
	return [self imageForName:imageName location:location];
}

/*
 
 image for name and location
 
 */
- (NSImage *)imageForName:(NSString *)name location:(NSString *)location
{
	// look for resource group icon
	if ([location caseInsensitiveCompare:MGSResourceGroupIcons] == NSOrderedSame) {
		
		// search array for matching group name
		for (NSDictionary *dict in [self groupResourceIcons]) {
			NSString *imageName = [dict objectForKey:MGSImageCollectionKeyName];
			if (!imageName) continue;
			if ([imageName caseInsensitiveCompare:name] == NSOrderedSame) {
				return [[dict objectForKey:MGSImageCollectionKeyImage] copy];
			}
		}
	}
	return nil;
}

/*
 
 default image for all group
 
 */
- (NSImage *)defaultImageForAllGroup
{
	return [self imageForName:DEFAULT_ALL_GROUP_IMAGE_NAME location:MGSResourceGroupIcons];
}
/*
 
 default image for group
 
 */
- (NSImage *)defaultImageForGroup
{
	return [self imageForName:DEFAULT_GROUP_IMAGE_NAME location:MGSResourceGroupIcons];
}
@end
