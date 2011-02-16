//
//  MGSScriptComponent.m
//  Mother
//
//  Created by Jonathan on 08/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
    cd /Users/Jonathan/Documents/Computing/xcode/Mother/trunk
    /Developer/usr/bin/gcc-4.0 -o /Users/Jonathan/Documents/Computing/xcode/Mother/trunk/build/Mother.build/Debug/Mother.build/Objects-normal/ppc/Mother -L/Users/Jonathan/Documents/Computing/xcode/Mother/trunk/build/Debug -F/Users/Jonathan/Documents/Computing/xcode/Mother/trunk/build/Debug -filelist /Users/Jonathan/Documents/Computing/xcode/Mother/trunk/build/Mother.build/Debug/Mother.build/Objects-normal/ppc/Mother.LinkFileList -framework Cocoa -framework MGSMother -arch ppc -mmacosx-version-min=10.5 -isysroot /Developer/SDKs/MacOSX10.5.sdk

#import "MGSScriptComponent.h"
#import "MGSScriptPlist.h"

@implementation MGSScriptComponent

- (id)init
{
	if ([super init]) {
		//
		// note that it might be better to look at the main bundle's list of support localizations
		//
		NSUserDefaults* defs = [NSUserDefaults standardUserDefaults];
		NSArray* languages = [defs objectForKey:@"AppleLanguages"];
		NSString* preferredLang = [languages objectAtIndex:0];
		_preferredLang = [@"-" stringByAppendingString:preferredLang];
	}
	return self;		 
}

// this object is merely a wrapper for the dictionary object.
// hence we only need a ref to the dictionary not a copy
- (void)setScriptDict:(NSDictionary *)dict
{
	NSAssert(dict, @"script dict is nil"); 
	_scriptDict = dict;
}
- (NSDictionary *)scriptDict
{
	return _scriptDict;
}

- (NSString *)name
{
	return [self stringForKey:(NSString *)MGSScriptKeyName];
}
- (NSString *)description
{
	return [self stringForKey:(NSString *)MGSScriptKeyDescription ];
}
- (NSString *)stringForKey:(NSString *)key
{
	NSAssert(_scriptDict, @"script dict is nil");
	
	// stringForKey:appending is a category on NSDictionary
	return [_scriptDict stringForKey:(NSString *)key appending:_preferredLang];
}

@end
