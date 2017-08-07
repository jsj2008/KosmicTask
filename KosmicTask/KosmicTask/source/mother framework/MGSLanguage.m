//
//  MGSLanguage.m
//  KosmicTask
//
//  Created by Jonathan on 10/11/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSLanguage.h"
#import "MGSLanguageProperty.h"

NSString *MGSInputStyle = @"InputStyle";
NSString *MGSLanguageCodeTemplateResourcePath = @"Mustache";
NSString *MGSTemplatePattern = @".pattern";

#define MGS_PROP_COPY(METHOD) self.METHOD = copy.METHOD

// class extension
@interface MGSLanguage()
- (void)getSystemVersionMajor:(unsigned *)major
                        minor:(unsigned *)minor
                       bugFix:(unsigned *)bugFix;
@end

@implementation MGSLanguage


// keep the order here to check against - copyWithZone
@synthesize initExecutorProcessType, 
initBuildProcessType, 
initSeparateSyntaxChecker,
initExecutableFormat,
initExecutorAcceptsOptions,
initBuildAcceptsOptions,
defExternalExecutorPath,
defExternalBuildPath,
defExecutorOptions,
defBuildOptions,
defCanBuild,
initIsOsaLanguage,
defScriptType,
defScriptTypeFamily,
initCanIgnoreBuildWarnings,
defTaskProcessName,
initValidForOSVersion,
initLanguageShipsWithOS,
initLanguageType,
initSupportsScriptFunctions,
initSupportsDirectParameters,
initSupportsClasses,
initSupportsClassFunctions,
defDefaultClass,
defDefaultScriptFunction,
defDefaultClassFunction,
defRequiredClass,
defRequiredScriptFunction,
defRequiredClassFunction,
defRequiredClassFunctionIsStatic,
initOnRunTask,
defRunFunction,
defRunClass,
defSourceFileExtensions,
initIsCocoaBridge,
initNativeObjectsAsResults,
initNativeObjectsAsYamlSupport,
defDisplayName,
defSyntaxDefinition,
defTaskRunnerClassName,
initBuildResultFlags,
initInputArgumentName,
initInputArgumentCase,
initInputArgumentStyle,
initInputArgumentStyleAllowedFlags;

#pragma mark -
#pragma mark Class methods
/*
 
 + missingProperty
 
 */
+ (NSString *)missingProperty
{
	return @"__$:missing-property:$";;
}

/*
 
 + tokeniseString:
 
 */
+ (NSMutableArray *)tokeniseString:(NSString *)optionString
{
	
	NSMutableArray *tokens = [NSMutableArray new];
	
	// if string empty return empty array
	if (!optionString || [optionString length] == 0) {
		return tokens;
	}
	
	NSScanner *scanner = [NSScanner scannerWithString:optionString];
	
	NSCharacterSet *whiteSpaceChars = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	NSCharacterSet *quoteChars = [NSCharacterSet characterSetWithCharactersInString:@"'\""];
	
	@try {
		while (![scanner isAtEnd]) {
			
			NSCharacterSet *separateChars = whiteSpaceChars;
			NSMutableString *token = [NSMutableString new];
			NSString *fragment = nil;
			NSString *quoteString = nil;
			
			// skip white space
			[scanner scanCharactersFromSet:whiteSpaceChars intoString:nil];
			if ([scanner isAtEnd]) break;
			
			// look for quote character at next location
			unichar ch = [[scanner string] characterAtIndex:[scanner scanLocation]];
			if ([quoteChars characterIsMember:ch]) {

				// get quote char string
				quoteString = [NSString stringWithCharacters:&ch length:1];

				// append quote to token
				[token appendString:quoteString];

				// scan over quote
				[scanner scanString:quoteString intoString:NULL];
				
				// we want to scan up to our quote string
				separateChars = [NSCharacterSet characterSetWithCharactersInString:quoteString];
			} 

			BOOL tokenIsComplete = YES;
			
			while (![scanner isAtEnd]) {
				
				// scan up to separator
				[scanner scanUpToCharactersFromSet:separateChars intoString:&fragment];
				if (fragment) {
					[token appendString:fragment];
				}
				
				// if not quoted we are done
				if (!quoteString) {
					break;
				}
				
				// token is not yet complete as we await our quote
				tokenIsComplete = NO;
				
				// if we have reached the end of the string then our closing quote was not found
				if ([scanner isAtEnd]) {
					break;
				}
				
				// get prev char as string
				NSString *prev = [[scanner string] substringWithRange:NSMakeRange([scanner scanLocation]-1, 1)];

				// append quote to token
				[token appendString:quoteString];
				
				// scan over
				[scanner scanString:quoteString intoString:NULL];

				// if no escape found we are done
				if (![prev isEqualToString:@"\\"]) {
					tokenIsComplete = YES;
					break;
				}
			}
			
			// if the token was not complete return nil
			if (!tokenIsComplete) {
				NSLog(@"token incomplete");
				return nil;
			}
			
			if (token) {
				[tokens addObject:token];
			}
		}
	} @catch (NSException *e) {
		NSLog(@"%@", e);
		
		return [NSMutableArray new];
	}
	return tokens;
}

#pragma mark -
#pragma mark Instance methods
/*
 
 - init
 
 */
- (id)init
{
	self = [super init];
	if (self) {
		
		// the init properties are only used to initialise the
		// instance. once initialised the actual properties are accessed
		// via the -languageProperties method 
		initExecutorProcessType = kMGSInProcess;
		initBuildProcessType = kMGSInProcess;
		initSeparateSyntaxChecker = NO;
		initExecutableFormat = kMGSSource;
		initLanguageType = kMGSInterpretedLanguage;
		initExecutorAcceptsOptions = NO;
		initBuildAcceptsOptions = NO;
		defCanBuild = YES;
		defExternalExecutorPath = [self missingProperty];
		defExternalBuildPath = [self missingProperty];
		defExecutorOptions = @"";
		defBuildOptions = @"";
		initIsOsaLanguage = NO;
		
		// script type
		defScriptType = [self missingProperty];
		defScriptTypeFamily = [self missingProperty];
		defDisplayName = [self missingProperty];
		defSyntaxDefinition = [self missingProperty];
		
		defTaskRunnerClassName = [self missingProperty];
		defTaskProcessName = [self missingProperty];

		initValidForOSVersion = YES;
		initCanIgnoreBuildWarnings = NO;
		initLanguageShipsWithOS = NO;
		
		initBuildResultFlags = 0;
		
		// interface
		initSupportsDirectParameters = NO;
		initSupportsScriptFunctions = NO;
		initSupportsClasses = NO;
		initSupportsClassFunctions = NO;
		defRequiredClassFunctionIsStatic = NO;
		defDefaultClass = @"kosmicTask";
		defDefaultScriptFunction = @"kosmicTask";
		defDefaultClassFunction = @"kosmicTask";
		defRequiredClass = nil;
		defRequiredScriptFunction = nil;
		defRequiredClassFunction = nil;
		
		// run configuration
		initOnRunTask = kMGSOnRunCallNone;
		defRunFunction = nil;
		defRunClass = nil;
		
		// Cocoa
		initIsCocoaBridge = NO;
		
		// Result representation
		initNativeObjectsAsResults = NO;
		initNativeObjectsAsYamlSupport = NO;
		
		// source file extensions
		defSourceFileExtensions = [NSArray new];
        
        // code template processing
        initInputArgumentName = kMGSInputArgumentName;
        initInputArgumentCase = kMGSInputArgumentCamelCase;
        initInputArgumentStyle = kMGSInputArgumentWhitespaceRemoved;
        initInputArgumentStyleAllowedFlags = kMGSInputArgumentUnderscoreSeparated |
                                                kMGSInputArgumentWhitespaceRemoved;
	}
	return self;
}

#pragma mark -
#pragma mark Missing value handling

/*
 
 - missingProperty
 
 */
- (NSString *)missingProperty
{
	return [[self class] missingProperty];
}

/*
 
 - isMissingProperty:
 
 */
- (BOOL)isMissingProperty:(id)value
{
	if ([value isKindOfClass:[NSString class]]) {
		return [value isEqualToString:[self missingProperty]];
	}
	return NO;
}
#pragma mark -
#pragma mark NSCopying
/*
 
 - copyWithZone:
 
 */
- (id)copyWithZone:(NSZone *)zone
{
	MGSLanguage *copy = [[[self class] alloc] init];

	#pragma unused(zone)
	
	// same order as property synthesizers
	MGS_PROP_COPY(initExecutorProcessType);
	MGS_PROP_COPY(initBuildProcessType); 
	MGS_PROP_COPY(initSeparateSyntaxChecker);
	MGS_PROP_COPY(initExecutableFormat);
	MGS_PROP_COPY(initExecutorAcceptsOptions);
	MGS_PROP_COPY(initBuildAcceptsOptions);
	MGS_PROP_COPY(defExternalExecutorPath);
	MGS_PROP_COPY(defExternalBuildPath);
	MGS_PROP_COPY(defExecutorOptions);
	MGS_PROP_COPY(defBuildOptions);
	MGS_PROP_COPY(defCanBuild);
	MGS_PROP_COPY(initIsOsaLanguage);
	MGS_PROP_COPY(defScriptType);
	MGS_PROP_COPY(defScriptTypeFamily);
	MGS_PROP_COPY(initCanIgnoreBuildWarnings);
	MGS_PROP_COPY(defTaskProcessName);
	MGS_PROP_COPY(initValidForOSVersion);
	MGS_PROP_COPY(initLanguageShipsWithOS);
	MGS_PROP_COPY(initLanguageType);
	MGS_PROP_COPY(initSupportsScriptFunctions);
	MGS_PROP_COPY(initSupportsDirectParameters);
	MGS_PROP_COPY(initSupportsClasses);
	MGS_PROP_COPY(initSupportsClassFunctions);
	MGS_PROP_COPY(defDefaultClass);
	MGS_PROP_COPY(defDefaultScriptFunction);
	MGS_PROP_COPY(defDefaultClassFunction);
	MGS_PROP_COPY(defRequiredClass);
	MGS_PROP_COPY(defRequiredScriptFunction);
	MGS_PROP_COPY(defRequiredClassFunction);
	MGS_PROP_COPY(defRequiredClassFunctionIsStatic);
	MGS_PROP_COPY(initOnRunTask);
	MGS_PROP_COPY(defRunFunction);
	MGS_PROP_COPY(defRunClass);
	MGS_PROP_COPY(defSourceFileExtensions);
	MGS_PROP_COPY(initIsCocoaBridge);
	MGS_PROP_COPY(initNativeObjectsAsResults);
	MGS_PROP_COPY(initNativeObjectsAsYamlSupport);
	MGS_PROP_COPY(defDisplayName);
	MGS_PROP_COPY(defSyntaxDefinition);
	MGS_PROP_COPY(defTaskRunnerClassName);
	MGS_PROP_COPY(initBuildResultFlags);
    MGS_PROP_COPY(initInputArgumentName);
    MGS_PROP_COPY(initInputArgumentCase);
    MGS_PROP_COPY(initInputArgumentStyle);
    MGS_PROP_COPY(initInputArgumentStyleAllowedFlags);
    
	return copy;
}

#pragma mark -
#pragma mark Accessors
/*
 
 - defScriptTypeFamily
 
 */
- (NSString *)defScriptTypeFamily 
{
	return [self isMissingProperty:defScriptTypeFamily] ? self.defScriptType  : defScriptTypeFamily;
}

/*
 
 - defDisplayName
 
 */
- (NSString *)defDisplayName
{
	return [self isMissingProperty:defDisplayName] ? self.defScriptType : defDisplayName;
}


/*
 
 - defSyntaxDefinition
 
 */
- (NSString *)defSyntaxDefinition
{
	return [self isMissingProperty: defSyntaxDefinition] ? self.defScriptTypeFamily : defSyntaxDefinition;
}

#pragma mark -
#pragma mark Code generation

/*
 
 - taskInputNameCodeTemplateName:
 
 */
- (NSString *)taskInputNameCodeTemplateName:(NSDictionary *)taskInfo
{
#pragma unused(taskInfo)
    
    return @"task-input-name";
}

/*
 
 - taskInputCodeTemplateName:
 
 */
- (NSString *)taskInputCodeTemplateName:(NSDictionary *)taskInfo
{
    #pragma unused(taskInfo)
    
    return @"task-input";
}


/*
 
 - taskInputResultCodeTemplateName:
 
 */
- (NSString *)taskInputResultCodeTemplateName:(NSDictionary *)taskInfo
{
#pragma unused(taskInfo)
    
    return @"task-input-result";
}

/*
 
 - taskHeaderCodeTemplateName:
 
 */
- (NSString *)taskHeaderCodeTemplateName:(NSDictionary *)taskInfo
{
#pragma unused(taskInfo)
    
    return @"task-header";
}

/*
 
 - taskInputsCodeTemplateName:
  
 */
- (NSString *)taskInputsCodeTemplateName:(NSDictionary *)taskInfo
{
#pragma unused(taskInfo)
    
    return @"task-input-variables";
}
/*
 
 - taskInputsPatternTemplateName:
 
 */
- (NSString *)taskInputsPatternTemplateName:(NSDictionary *)taskInfo
{
#pragma unused(taskInfo)
    
    return [[self taskInputsCodeTemplateName:taskInfo] stringByAppendingString:MGSTemplatePattern];
}

/*
 
 - taskFunctionCodeTemplateName:
 
 */
- (NSString *)taskFunctionCodeTemplateName:(NSDictionary *)taskInfo
{
#pragma unused(taskInfo)
    
    return @"task-function";
    
     
}
/*
 
 - taskFunctionPatternTemplateName:
 
 */
- (NSString *)taskFunctionPatternTemplateName:(NSDictionary *)taskInfo
{
#pragma unused(taskInfo)
    
    return [[self taskFunctionCodeTemplateName:taskInfo] stringByAppendingString:MGSTemplatePattern];
}

/*
 
 - taskClassFunctionCodeTemplateName:
 
 */
- (NSString *)taskClassFunctionCodeTemplateName:(NSDictionary *)taskInfo
{
#pragma unused(taskInfo)
    
    return @"task-class-function";
}
/*
 
 - taskClassFunctionPatternTemplateName:
 
 */
- (NSString *)taskClassFunctionPatternTemplateName:(NSDictionary *)taskInfo
{
#pragma unused(taskInfo)
    
    return [[self taskClassFunctionCodeTemplateName:taskInfo] stringByAppendingString:MGSTemplatePattern];
}

/*
 
 - taskInputVariablesCodeTemplateName:
 
 */
- (NSString *)taskInputVariablesCodeTemplateName:(NSDictionary *)taskInfo
{
#pragma unused(taskInfo)
    
    return @"task-input-variables";
}
/*
 
 - taskClassFunctionPatternTemplateName:
 
 */
- (NSString *)taskInputVariablesPatternTemplateName:(NSDictionary *)taskInfo
{
#pragma unused(taskInfo)
    
    return [[self taskInputVariablesCodeTemplateName:taskInfo] stringByAppendingString:MGSTemplatePattern];
}

/*
 
 - taskBodyCodeTemplateName:
 
 */
- (NSString *)taskBodyCodeTemplateName:(NSDictionary *)taskInfo
{
    NSString *templateName = nil;  
    NSNumber *onRun = [taskInfo objectForKey:@"onRun"];
    
    if (!onRun) {
        onRun = @(kMGSOnRunCallScript);
    }
    
    NSAssert([onRun isKindOfClass:[NSNumber class]], @"Expected NSNumber");
    
    switch ([onRun integerValue]) {
            
        case kMGSOnRunCallScript:
            templateName = @"task-body";
            break;
            
        case kMGSOnRunCallScriptFunction:
            templateName = @"task-function-body";
            break;
            
        case kMGSOnRunCallClassFunction:
            templateName = @"task-class-body";
            break;

        case kMGSOnRunCallNone:
        default:
            break;

    }
    
    return templateName;
}

/*
 
 - taskInputConditionalCodeTemplateName:
 
 */
- (NSString *)taskInputConditionalCodeTemplateName:(NSDictionary *)taskInfo
{
#pragma unused(taskInfo)
    
    return @"task-input-conditional";
}

/*
 
 - codeProperties
 
 */
- (NSDictionary *)codeProperties
{
    NSMutableDictionary *codeProps = [NSMutableDictionary dictionaryWithCapacity:2];
    
    // do we pass inputs as variables or via a function
    NSString *inputStyle = nil;
    if (initExecutorProcessType == kMGSInProcess) {
       inputStyle = @"function";
    } else {
       inputStyle = @"variable"; 
    }
    [codeProps setObject:inputStyle forKey:MGSInputStyle];
     
    return codeProps;
}

/*
 
 - codeTemplateResourcePath
 
 */

- (NSString *)codeTemplateResourcePath
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *resourcePath = [bundle resourcePath];
    NSString *codeTemplateResourcePath = [resourcePath stringByAppendingPathComponent:MGSLanguageCodeTemplateResourcePath];
    
    return codeTemplateResourcePath;
}
#pragma mark -
#pragma mark System version
/*
 
 - validateOSVersion
 
 */
- (BOOL)validateOSVersion:(unsigned)major minor:(unsigned)minor bugFix:(unsigned)bugFix
{
	unsigned _major, _minor, _bugFix;
	[self getSystemVersionMajor:&_major minor:&_minor bugFix:&_bugFix];
	
	if  (_major > major) {
		return YES;
	} else if (_major == major && _minor > minor) {
		return YES;
	} else if ((_major == major && _minor == minor && _bugFix >= bugFix)) {
		return YES;
	}
	
	return NO;
	
}
/*
 
 get system version
 
 */
- (void)getSystemVersionMajor:(unsigned *)major
                        minor:(unsigned *)minor
                       bugFix:(unsigned *)bugFix
{
    OSErr err;
    SInt32 systemVersion, versionMajor, versionMinor, versionBugFix;
    if ((err = Gestalt(gestaltSystemVersion, &systemVersion)) != noErr) goto fail;
    if (systemVersion < 0x1040)
    {
        if (major) *major = ((systemVersion & 0xF000) >> 12) * 10 +
            ((systemVersion & 0x0F00) >> 8);
        if (minor) *minor = (systemVersion & 0x00F0) >> 4;
        if (bugFix) *bugFix = (systemVersion & 0x000F);
    }
    else
    {
        if ((err = Gestalt(gestaltSystemVersionMajor, &versionMajor)) != noErr) goto fail;
        if ((err = Gestalt(gestaltSystemVersionMinor, &versionMinor)) != noErr) goto fail;
        if ((err = Gestalt(gestaltSystemVersionBugFix, &versionBugFix)) != noErr) goto fail;
        if (major) *major = versionMajor;
        if (minor) *minor = versionMinor;
        if (bugFix) *bugFix = versionBugFix;
    }
    
    return;
    
fail:
    NSLog(@"Unable to obtain system version: %ld", (long)err);
    if (major) *major = 10;
    if (minor) *minor = 0;
    if (bugFix) *bugFix = 0;
}

@end
