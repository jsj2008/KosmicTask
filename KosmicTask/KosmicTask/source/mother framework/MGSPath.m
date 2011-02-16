//
//  MGSPath.m
//  Mother
//
//  Created by Jonathan on 21/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
#import <sys/stat.h>
#import "MGSPath.h"
#import "MGSMother.h"


// at present Spotlight cannot index inside packages.
// you can define a UTI for the package and have an importer run against the package
// but the index is against the package path, not the the contained file path.
//NSString *MGSUserDocumentPath = @"~/Documents/KosmicTask/User.kosmictask-pack";
//NSString *MGSApplicationDocumentPath = @"~/Documents/KosmicTask/Application.kosmictask-pack";
NSString *MGSUserDocumentPath = @"~/Documents/KosmicTask/User Tasks";
NSString *MGSApplicationDocumentPath = @"~/Documents/KosmicTask/Application Tasks";
NSString *MGSUserApplicationSupportPath =  @"~/Library/Application Support/KosmicTask/";
NSString *MGSApplicationSupportPath = @"/Library/Application Support/KosmicTask/";


@implementation MGSPath

// path to application support 
// this method will create the folder if it does not exist
/*
Notation of traditional Unix permissions

[edit]Symbolic notation
There are many ways by which Unix permission schemes are represented. The most common form is symbolic notation. This scheme represents permissions as a series of 10 characters.
First Character
-	a regular file
d	a directory
l	a symbolic link
Three groups of three
first	what the owner can do
second	what the group members can do
third	what other users can do
The triplet
first	r: readable.
second	w: writable.
third	x: executable.
other: see below.
The first character indicates the file type:
- denotes a regular file
d denotes a directory
b denotes a block special file
c denotes a character special file
l denotes a symbolic link
p denotes a named pipe
s denotes a domain socket
Each class of permissions is represented by three characters. The first set of characters represents the user class. The second set represents the group class. The third and final set of three characters represents the others class.
Each of the three characters represent the read, write, and execute permissions respectively:
r if the read bit is set, - if it is not.
w if the write bit is set, - if it is not.
x if the execute bit is set, - if it is not.
The x will be an s if the setuid or setgid bit is also set, and in the third, it will be a t if the sticky bit is set. If these are set but the execute bit is not, the letter will be in uppercase.
The following are some examples of symbolic notation:
-rwxr-xr-x for a regular file whose user class has full permissions and whose group and others classes have only the read and execute permissions.
crw-rw-r-- for a character special file whose user and group classes have the read and write permissions and whose others class has only the read permission.
dr-x------ for a directory whose user class has read and execute permissions and whose group and others classes have no permissions.
[edit]Symbolic notation and additional permission
The three additional permissions are indicated by changing one of the three "execute" characters as shown in the following table:
Permission	Class	Executable1	Non-executable2
Set User ID (setuid)	User	s	S
Set Group ID (setgid)	Group	s	S
Sticky bit	Others	t	T
The character that will be used to indicate that the execute bit is also set.
The character that will be used when the execute bit is not set.
Here is an example:
"-rwsr-Sr-x" for a file whose user class has read, write and execute permissions; whose group class has read permission; whose others class has read and execute permissions; and which has setuid and setgid permissions set.
[edit]Octal notation
Another common method for representing Unix permissions is octal notation. Octal notation consists of a three- or four-digit base-8 value.
With three-digit octal notation, each numeral represents a different component of the permission set: user class, group class, and "others" class respectively.
Each of these digits is the sum of its component bits (see also Binary numeral system). As a result, specific bits add to the sum as it is represented by a numeral:
The read bit adds 4 to its total (in binary 100),
The write bit adds 2 to its total (in binary 010), and
The execute bit adds 1 to its total (in binary 001).
These values never produce ambiguous combinations; each sum represents a specific set of permissions.
These are the examples from the Symbolic notation section given in octal notation:
"-rwxr-xr-x" would be represented as 755 in three-digit octal.
"-rw-rw-r--" would be represented as 664 in three-digit octal.
"-r-x------" would be represented as 500 in three-digit octal.
Here is a summary of the meanings for individual octal digit values:
1 --x execute 
2 -w- write 
3 -wx write and execute
4 r-- read
5 r-x read and execute
6 rw- read and write
7 rwx read, write and execute
 */
// note that non admins will not be able to create this path
+ (NSString *)verifyApplicationSupportPath
{
	NSString *folder = [self applicationSupportPath];
	if (![[NSFileManager defaultManager] fileExistsAtPath:folder])
	{
		return [self createFolder:folder withAttributes:[self adminFileAttributes]];
	}     
	return folder;
}

// path to user application support
// this method will create the folder if it does not exist
+ (NSString *)verifyUserApplicationSupportPath
{
	NSString *folder = [self userApplicationSupportPath];
	if (![[NSFileManager defaultManager] fileExistsAtPath:folder])
	{
		return [self createFolder:folder withAttributes:[self userFileAttributes]];
	}     
	return folder;
}

/*
 
 verify user document path
 
 */
+ (NSString *)verifyUserDocumentPath
{
	NSString *folder = [self userDocumentPath];
	if (![[NSFileManager defaultManager] fileExistsAtPath:folder])
	{
		return [self createFolder:folder withAttributes:[self userFileAttributes]];
	}     
	return folder;
}

/*
 
 verify application document path
 
 */
+ (NSString *)verifyApplicationDocumentPath
{
	NSString *folder = [self applicationDocumentPath];
	if (![[NSFileManager defaultManager] fileExistsAtPath:folder])
	{
		return [self createFolder:folder withAttributes:[self userFileAttributes]];
	}     
	return folder;
}

/*
 
 create folder with attributes
 
 */
+ (NSString *)createFolder:(NSString *)folder withAttributes:(NSDictionary *)attributes
{
	BOOL createSuccess = [[NSFileManager defaultManager] createDirectoryAtPath:folder withIntermediateDirectories:YES attributes: attributes error:NULL];
	if (!createSuccess) {
		MLog(DEBUGLOG, @"could not create folder: %@", folder);
		return nil;
	}
	
	return folder;
}

/*
 
 user file attributes
 
 */
+ (NSDictionary *)userFileAttributes
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithUnsignedLong:S_IFDIR | 0755], NSFilePosixPermissions,
			nil];
}

/*
 
 user file attributes
 
 */
+ (NSDictionary *)adminFileAttributes
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithUnsignedLong:S_IFDIR | 0775], NSFilePosixPermissions,
			nil];
}

/*
 
 user document path
 
 */
+ (NSString *)userDocumentPath
{
	return [MGSUserDocumentPath stringByExpandingTildeInPath];
}

/*
 
 application document path
 
 */
+ (NSString *)applicationDocumentPath
{
	return [MGSApplicationDocumentPath stringByExpandingTildeInPath];
}

/*
 
 application support path
 
 */
+ (NSString *)applicationSupportPath
{
	return MGSApplicationSupportPath;
}

/*
 
 user application support path
 
 */
+ (NSString *)userApplicationSupportPath
{
	return [MGSUserApplicationSupportPath stringByExpandingTildeInPath];
}

/*
 
 user document path exists
 
 */
+ (BOOL)userDocumentPathExists
{
	return [[NSFileManager defaultManager] fileExistsAtPath:[self userDocumentPath]];
}

/*
 
 application document path exists
 
 */
+ (BOOL)applicationDocumentPathExists
{
	return [[NSFileManager defaultManager] fileExistsAtPath:[self applicationDocumentPath]];
}

/*
 
 application support path exists
 
 */
+ (BOOL)applicationSupportPathExists
{
	return [[NSFileManager defaultManager] fileExistsAtPath:[self applicationSupportPath]];
}

/*
 
 user application support path exists
 
 */
+ (BOOL)userApplicationSupportPathExists
{
	return [[NSFileManager defaultManager] fileExistsAtPath:[self userApplicationSupportPath]];
}



// return host name minus its local link (.local.) if it exits
+ (NSString *)hostNameMinusLocalLink:(NSString *)hostName
{
	// need to deal with fully qualified domain names eg: .local.
	// but could have jonathan.local.local. ?
	// divide string at periods.
	// if string starts or ends with period that array element will be empty
	NSArray *array = [hostName componentsSeparatedByString:@"."];
	int count = [array count];
	if (count == 0) {
		return nil;
	}
	
	NSMutableArray *mArray = [NSMutableArray arrayWithArray:array];

	// remove first empty string (indicates name begining with .)
	if ([[mArray objectAtIndex:0] isEqualToString:@""]) {
		[mArray removeObjectAtIndex:0];
	}
	// remove last empty string
	if ([[mArray lastObject] isEqualToString:@""]) {
		[mArray removeLastObject];
	}
	
	// remove last instance of local
	if ([[mArray lastObject] isEqualToString:@"local"]) {
		[mArray removeLastObject];
	}
	
	// join the hostname up again
	// note that if the hostname began with . it will be removed
	// though it is not legal to begin a hostname so
	NSString *name = [mArray componentsJoinedByString:@"."];
		 
	return name;
}

/*
 
 + validateFilenameCharacters
 
 */
+ (NSString *)validateFilenameCharacters:(NSString *)filename
{
	filename = [filename stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
	filename = [filename stringByReplacingOccurrencesOfString:@"\0" withString:@"-"];

	return filename;
}
@end
