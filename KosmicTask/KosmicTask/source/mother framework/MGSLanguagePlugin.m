 //
//  MGSLanguagePlugin.m
//  KosmicTask
//
//  Created by Jonathan on 26/04/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSLanguagePlugin.h"
#import "NSApplication_Mugginsoft.h"
#import "MGSImageManager.h"
#import "MGSTempStorage.h"
#import "MGSLanguagePropertyManager.h"

NSString *MGSLanguagePluginDefaultClassName = @"MGSDefaultLanguagePluginClassName";
NSString *MGSLangPluginExecutePath = @"MGSLangPluginExecutePath";
NSString *MGSLangPluginTempPath = @"MGSLangPluginTempPath";
NSString *MGSLangPluginNetRequest = @"MGSLangPluginNetRequest";

static unsigned mgs_major = 0, mgs_minor = 0, mgs_bugFix = 0;

// class interface
@interface MGSLanguagePlugin ()
- (NSMutableDictionary *)standardTaskDictionaryForScript:(MGSScript *)script;
- (void)exportBundleResources:(NSString *)folderName;

@property (assign) MGSLanguage *language;
@end

static NSOperationQueue *operationQueue = nil;

@implementation MGSLanguagePlugin

@synthesize applicationResourcesManager, userResourcesManager, language, languagePropertyManager;

/*
 
 + initialize
 
 */

+ (void)initialize
{
	if ( self == [MGSLanguagePlugin class] ) {
		operationQueue = [[NSOperationQueue alloc] init];
		
		[NSApplication getSystemVersionMajor:&mgs_major minor:&mgs_minor bugFix:&mgs_bugFix];
		
	}
	
	// register subclass with the language node
	[MGSResourceBrowserNode registerClass:self
								  options:[NSDictionary dictionaryWithObjectsAndKeys:@"scriptType", @"name", nil]];
	
}

/*
 
 - init
 
 designated initialiser
 
 */
- (id)init
{
	self = [super init];
	if (self) {
		
		// allocate a language
		self.language = [[[self languageClass] alloc ] init];

		// allocate a property manager
		languagePropertyManager = [[[self propertyManagerClass] alloc] initWithLanguage:self.language];
		
		// run plugin configuration
		[self configureLanguageProperties:languagePropertyManager];
				
		[languagePropertyManager initialiseProperties];
	} 
	
	return self;
}

/*
 
 - propertyManagerClass
 
 */
- (Class)propertyManagerClass
{
	// subclasses may override theis method to provide a custom manager
	return [MGSLanguagePropertyManager class];
}

/*
 
 - languageClass
 
 */
- (Class)languageClass
{
	// subclasses must override this method to provide a language class
	NSAssert(NO, @"subclasses must override");
	
	return nil;
}

#pragma mark -
#pragma mark Resources

/*
 
 - loadApplicationResourcesAtPath:name:
 
 */
- (void) loadApplicationResourcesAtPath:(NSString *)path name:(NSString *)name
{
	if (applicationResourcePath) {
		MLogInfo(@"application resources already loaded");
		return;
	}
	
	// ensure that the parent path exists
	NSString *parentPath = [path stringByAppendingPathComponent:name];
	NSFileManager *fm = [NSFileManager defaultManager];
	if (![fm fileExistsAtPath:parentPath]) {
		if (![fm createDirectoryAtPath:parentPath 
					withIntermediateDirectories:YES attributes:nil error:NULL]) {
			MLogInfo(@"Cannot create resource parent folder: %@", parentPath);
			return;
		}
	}
		
	applicationResourcePath = path;
	applicationResourceName = name;
	
	// export the bundle resources on the op queue.
	// this should help to keep launch times down.
	
	// templates
	NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self
									selector:@selector(exportBundleResources:) object:@"Templates"];
	[operationQueue addOperation:theOp];
	
	// documents
	theOp = [[NSInvocationOperation alloc] initWithTarget:self
								selector:@selector(exportBundleResources:) object:@"Documents"];
	[operationQueue addOperation:theOp];
	
	// settings
	theOp = [[NSInvocationOperation alloc] initWithTarget:languagePropertyManager
												 selector:@selector(exportLanguagePropertiesAtPath:) object:parentPath];
	[operationQueue addOperation:theOp];
}

/*
 
 - saveSettings
 
 */
- (BOOL)saveSettings
{
	return [languagePropertyManager saveLanguageProperties];
}

/*
 
 - loadUserResourcesAtPath:name:
 
 */
- (void) loadUserResourcesAtPath:(NSString *)path name:(NSString *)name
{
	if (userResourcePath) {
		MLogInfo(@"user resources already loaded");
		return;
	}

	userResourcePath = path;
	userResourceName = name;

	
}

/*
 
 - exportBundleResources:
 
 */
- (void)exportBundleResources:(NSString *)folderName
{
	
	NSAssert(applicationResourcePath, @"applicationResourcePath path is nil");
	
	// copy bundle resources to target path
	NSString *targetPath = applicationResourcePath;
	targetPath = [targetPath stringByAppendingPathComponent:applicationResourceName];
	targetPath = [targetPath stringByAppendingPathComponent:folderName];
	
	NSFileManager *fm = [NSFileManager defaultManager];
	
	// make targetPath
	if (![fm fileExistsAtPath:targetPath]) {
		if (![fm createDirectoryAtPath:targetPath 
		   withIntermediateDirectories:YES 
							attributes:nil 
								 error:NULL]) {
			MLogInfo(@"Cannot create resource folder at %@", targetPath);
			return;
		}
	}
	
	// get plugin bundle resource path
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSString *bundleResourcePath = [bundle resourcePath];
	bundleResourcePath = [bundleResourcePath stringByAppendingPathComponent:@"Language"];
	bundleResourcePath = [bundleResourcePath stringByAppendingPathComponent:folderName];
	
	// get bundle resource file names to be copied
	NSArray *resourceFileNames = [fm contentsOfDirectoryAtPath:bundleResourcePath error:NULL];
	
	// copy resources to target path
	for (NSString *resourceFileName in resourceFileNames) {
		
		NSString *srcPath = [bundleResourcePath stringByAppendingPathComponent:resourceFileName];
		NSString *destPath = [targetPath stringByAppendingPathComponent:resourceFileName];
		
		if (![fm fileExistsAtPath:destPath]) {
			if (![fm copyItemAtPath:srcPath toPath:destPath error:NULL]) {
				MLogInfo(@"Cannot copy resource file from %@ to %@ ", srcPath, destPath);
				continue;
			}
		}
	}
}

/*
 
 -applicationResourcesManager
 
 */
- (MGSLanguageResourcesManager *)applicationResourcesManager
{
	// lazy allocation
	if (!applicationResourcesManager) {
				
		applicationResourcesManager = [[MGSApplicationLanguageResourcesManager alloc] initWithPath:applicationResourcePath name:applicationResourceName folder:nil];
		applicationResourcesManager.delegate = self;
		applicationResourcesManager.origin = MGSResourceOriginMugginsoft;
	}
	
	return applicationResourcesManager;
}

/*
 
 -userResourcesManager
 
 */
- (MGSLanguageResourcesManager *)userResourcesManager
{
	// lazy allocation
	if (!userResourcesManager) {
		userResourcesManager = [[MGSUserLanguageResourcesManager alloc] initWithPath:userResourcePath name:userResourceName folder:nil];
		userResourcesManager.delegate = self;
		userResourcesManager.origin = MGSResourceOriginUser;
	}
	
	return userResourcesManager;
}

/*
 
 - resourcesManager:cannotMutateWithSelector:object
 
 */
- (void)resourcesManager:(MGSResourcesManager *)manager cannotMutateWithSelector:(SEL)selector object:(id)object
{
	// applications resources could not be mutated so forward
	// to the user resources manager	
	if (manager == applicationResourcesManager) {
		[userResourcesManager mutateWithSelector:selector object:object];
	}
}
	
/*
 
 - resourcesManager:didMutate:
 
 */
- (void)resourcesManager:(MGSResourcesManager *)manager didMutate:(NSDictionary *)changes
{
	MGSResourcesManager *otherManager = nil;
	if (manager == applicationResourcesManager) {
		otherManager = userResourcesManager;
	} else {
		otherManager = applicationResourcesManager;
	}

	MGSResourceItem *resource = nil;
	
	// if assign default resource in one manager then clear it in the other
	if ([changes objectForKey:MGSDefaultResourceIDChanged]) {
		resource = [changes objectForKey:MGSDefaultResourceIDChanged];
		MGSResourcesManager *resourceManager = [otherManager managerForResourceClass:[resource class]];
		[resourceManager setDefaultResourceID:nil];
	}
}

/*
 
 - resourceTree
 
 */
- (MGSResourceBrowserNode *)resourceTreeAsCopy:(BOOL)copy
{
	/*
	 
	 We need to be able to generate indpedendent trees.
	 A master tree for the resource brower and copies for the resource sheets.
	 Even though the resource sheet tree is immutable we need a copy as we cannot have two
	 sets of bindings operating on the master tree.
	 */
	MGSResourcesManager *resourcesManager = nil;
	
	// get root node
	// regardless of the copy state the root node repObj is the plugin
	MGSResourceBrowserNode *rootTreeNode = [MGSResourceBrowserNode treeNodeWithRepresentedObject:self];

	// application resource node
	resourcesManager = copy ? [self.applicationResourcesManager copy] : self.applicationResourcesManager;
	MGSResourceBrowserNode *appTreeNode = [MGSResourceBrowserNode treeNodeWithRepresentedObject:resourcesManager];
	appTreeNode.image = [resourcesManager defaultNodeImage];
	[[rootTreeNode mutableChildNodes] addObject:appTreeNode];
	[resourcesManager addToTree:appTreeNode];
	
	// user resource node
	resourcesManager = copy ? [self.userResourcesManager copy] : self.userResourcesManager;
	MGSResourceBrowserNode *userTreeNode = [MGSResourceBrowserNode treeNodeWithRepresentedObject:resourcesManager];
	userTreeNode.image = [resourcesManager defaultNodeImage];	
	[[rootTreeNode mutableChildNodes] addObject:userTreeNode];
	[resourcesManager addToTree:userTreeNode];
		
	return rootTreeNode;
	 
}

/*
 
 - defaultTemplateResource
 
 */
- (MGSResourceItem *)defaultTemplateResource
{
	MGSResourceItem *resource = [self.applicationResourcesManager.templateManager defaultResource];
	if (!resource) {
		resource = [self.userResourcesManager.templateManager defaultResource];
	}
	
	return resource;
}
#pragma mark -
#pragma mark Language process

/*
 
 - configureLanguageProperties:
 
 */
- (void)configureLanguageProperties:(MGSLanguagePropertyManager *)manager
{
#pragma unused(manager)
	
}

/*
 
 - hasSourceFileExtension:
 
 */
- (BOOL)hasSourceFileExtension:(NSString *)extension
{
	MGSLanguageProperty *langProp = [languagePropertyManager propertyForKey:MGS_LP_SourceFileExtensions];
	NSArray *fileExtensions = [langProp value];
	if (![fileExtensions isKindOfClass:[NSArray class]]) return NO;
	
	for (NSString *fileExtension in fileExtensions) {
		if ([extension caseInsensitiveCompare:fileExtension] == NSOrderedSame) {
			return YES;
		}
	}
	
	return NO;
}
#pragma mark -
#pragma mark Version

/*
 
 - getSystemVersionMajor:minor:bugFix:
 
 */
- (void)getSystemVersionMajor:(unsigned *)major
                        minor:(unsigned *)minor
                       bugFix:(unsigned *)bugFix
{
	*major = mgs_major;
	*minor = mgs_minor;
	*bugFix = mgs_bugFix;
}

/*
 
 - syntaxDefinition
 
 */
- (NSString *)syntaxDefinition
{
	return self.language.initSyntaxDefinition;
}

/*
 
 - validateOSVersion
 
 */
- (BOOL)validateOSVersion
{
	unsigned major, minor, bugFix;
	[self getSystemVersionMajor:&major minor:&minor bugFix:&bugFix];
	
	if ((major == 10 && minor >= 5) || major > 10) {
		return YES;
	}
	
	return NO;
}

/*
 
 - isOSALanguage
 
 */
- (BOOL)isOSALanguage
{
	return self.language.initIsOsaLanguage;
}




#pragma mark -
#pragma mark Task

/*
 
 - taskDictForScript:options:error:
 
 */
- (NSDictionary *)taskDictForScript:(MGSScript *)script options:(NSDictionary *)options error:(MGSError **)mgsError
{
	NSString *error = nil;
	
	NSString *scriptPath = [options objectForKey:MGSLangPluginExecutePath];
	MGSNetRequest *netRequest = [options objectForKey:MGSLangPluginNetRequest];
	MGSNetMessage *requestMessage = [netRequest requestMessage];
	
	/*
	 
	 the script representation passed into this method may not contain the executable
	 data so load a full script representation from disk
	 
	 */
	MGSScript *fullScriptRep = [MGSScript scriptWithContentsOfFile:scriptPath error:mgsError];
	if (!fullScriptRep) {
		error = NSLocalizedString(@"cannot load script file", @"Script task process error");
		goto errorExit;
	}
	
	// script executable data.
	// this may be an NSData object containing compiled code (say AppleScript)
	// or a UTF8 encoded NSString instance of text to be interpreted
	NSData *executableData = [fullScriptRep executableData];
	if (!executableData) {
		error = NSLocalizedString(@"Task executable code cannot be found", @"Returned by server when task does not contain executable code");
		goto errorExit;
	}
	NSString *executableFormat = [[fullScriptRep scriptCode] compiledDataFormat];
	fullScriptRep = nil;
		
	//
	// get task dictionary
	//
	NSMutableDictionary *taskDict = [self standardTaskDictionaryForScript:script];
	
	//
	// script executable data  - mandatory
	//
	[taskDict setObject:executableData forKey:MGSScriptExecutable];
	if (executableFormat) {
		[taskDict setObject:executableFormat forKey:MGSScriptExecutableFormat];
	}
	
	//
	// user interaction mode 
	//
	NSNumber *userInteractionMode = [NSNumber numberWithInteger:[script userInteractionMode]];
	if (userInteractionMode) {
		[taskDict setObject:userInteractionMode forKey:MGSScriptUserInteraction];
	}
	
	//
	// origin is local host
	//
	BOOL originIsLocalHost = [requestMessage messageOriginIsLocalHost];
	if (originIsLocalHost) {
		[taskDict setObject:[NSNumber numberWithBool:originIsLocalHost] forKey:MGSScriptOriginIsLocalHost];
	}
	
	//
	// copy script parameter array details to task array
	// these may be any of the supported property list types
	// which will be coerced into a corresponding event descriptor data type
	// each item in script parameter array must by an NSDictionary
	//
	NSMutableArray *taskParamArray = [NSMutableArray arrayWithCapacity:2];
	NSArray *scriptParamArray = [script objectForKey: MGSScriptKeyParameters];
	for (id item in scriptParamArray) {
		
		// get individual script parameter dictionary
		if (![item isKindOfClass:[NSDictionary class]]) {
			error = NSLocalizedString(@"Script parameter list malformed", @"Returned by server when script parameter data is malformed");
			goto errorExit;
		}
		NSDictionary *params = (NSDictionary *)item;
		
		// get parameter value
		NSString *parameterValue = [params objectForKey:MGSScriptKeyValue];
		
		// use default, except default exists in the ClassInfo dict
		/*if (!parameterValue) {
			parameterValue = [params objectForKey:MGSScriptKeyDefault];
			MLog(DEBUGLOG, @"Using default parameter value.");
		} */
		
		// validate
		if (!parameterValue) {
			error = NSLocalizedString(@"No value found for parameter", @"Returned by server when script parameter value is missing");
			goto errorExit;
		}
		
		MLogDebug(@"Parameter class: %@", [parameterValue className]);
		MLog(DEBUGLOG, @"Parameter value: %@", parameterValue);
		
		// look for attachment index.
		// if an attachment index exists then the parameter value represents a file that has been passed
		// as an attachment.
		NSNumber *attachmentNumber = [params objectForKey:MGSScriptKeyAttachmentIndex];
		if (attachmentNumber && [attachmentNumber isKindOfClass:[NSNumber class]]) {
			NSUInteger attachmentIndex = [attachmentNumber integerValue]; 
			
			// get the attachment
			MGSNetAttachment *attachment = [netRequest.requestMessage.attachments attachmentAtIndex:attachmentIndex];
			if (!attachment) {
				error = NSLocalizedString(@"Invalid parameter attachment at index: %u", @"Returned by server when script attachment index invalid");
				error = [NSString stringWithFormat:error, attachmentIndex];
				goto errorExit;
			}
			
			// use attachment filepath as the parameter value.
			parameterValue = attachment.filePath;
			MLog(DEBUGLOG, @"Parameter value (updated from attachment): %@", parameterValue);
		}
		
		// add parameter value
		[taskParamArray addObject:parameterValue];
	}
	[taskDict setObject:taskParamArray forKey:MGSScriptParameters];
	
	// we want to execute this script
	[taskDict setObject:MGSScriptActionExecute forKey:MGSScriptAction];
	
	// executor path
	NSString *executorPath = [script externalExecutorPath];
	if (executorPath) {
		[taskDict setObject:executorPath forKey:MGSScriptExecutorPath];
	}
	
	// executor options
	NSString *executorOptions = [script executorOptions];
	if (executorOptions) {
		[taskDict setObject:executorOptions forKey:MGSScriptExecutorOptions];
	}
	
	return taskDict;
	
errorExit:
	
	if (!*mgsError) {
		*mgsError = [MGSError serverCode:MGSErrorCodeScriptExecute reason:error];
	}
	
	return nil;
}

/*
 
 - standardTaskDictionaryForScript:
 
 */
- (NSMutableDictionary *)standardTaskDictionaryForScript:(MGSScript *)script
{
	//
	// define a dictionary to pass into the task runner
	//
	// task will read dict from std in
	//
	NSMutableDictionary *taskDict = [NSMutableDictionary dictionaryWithCapacity:2];
	
	//
	// script type
	//
	[taskDict setObject:[self scriptType] forKey:MGSScriptType];
	
	//
	// script runner process and class
	//
	[taskDict setObject:[self taskRunnerPath] forKey:MGSScriptRunnerProcessPath];
	[taskDict setObject:[self taskRunnerClassName] forKey:MGSScriptRunnerClassName];
	
	// storage URL
	[taskDict setObject:[[MGSTempStorage sharedController] storageFolder] forKey:MGSScriptTempStorageReverseURL];

	//
	// script onRun - mandatory
	//
	NSNumber *scriptOnRun = [script onRun];
	[taskDict setObject:scriptOnRun forKey:MGSScriptOnRun];
	
	//
	// script runClass - optional
	//
	NSString *scriptRunClass = [script runClass];
	if (scriptRunClass) {
		[taskDict setObject:scriptRunClass forKey:MGSScriptRunClass];
	}
	
	//
	// script subroutine  - optional
	//
	NSString *scriptSubroutine = [script subroutine];
	if (scriptSubroutine) {
		[taskDict setObject:scriptSubroutine forKey:MGSScriptSubroutine];
	}
	
	return taskDict;
}


/*
 
 - scriptType
 
 */
- (NSString *)scriptType
{
	return self.language.initScriptType;
}

/*
 
 - scriptTypeFamily
 
 */
- (NSString *)scriptTypeFamily
{
	return self.language.initScriptTypeFamily;
}

/*
 
 - taskRunnerClassName
 
 */
- (NSString *)taskRunnerClassName
{
	return self.language.initTaskRunnerClassName;
}

/*
 
 - taskRunnerPath
 
 */
- (NSString *)taskRunnerPath
{
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSString *path = [bundle pathForAuxiliaryExecutable:[self taskProcessName]];
	return path;
}

/*
 
 - taskProcessName
 
 */
- (NSString *)taskProcessName
{
	return self.language.initTaskProcessName;
}

#pragma mark -
#pragma mark Build 

/*
 
 - buildResultFlags
 
 */
- (MGSBuildResultFlags)buildResultFlags
{
	return self.language.initBuildResultFlags;
}


/*
 
 - canIgnoreBuildWarnings
 
 */
- (BOOL)canIgnoreBuildWarnings
{
	return language.initCanIgnoreBuildWarnings;
}

/*
 
 - buildTaskDictForScript:options:error:
 
 */
- (NSDictionary *)buildTaskDictForScript:(MGSScript *)script options:(NSDictionary *)options error:(MGSError **)mgsError
{
#pragma unused(options)
	
	NSString *error = nil;
	
	//
	// get task dictionary
	//
	NSMutableDictionary *taskDict = [self standardTaskDictionaryForScript:script];
	if (!taskDict) {
		error = NSLocalizedString(@"Task dictionary is empty", @"Returned by server when task script dictionary is empty");
		goto errorExit;	
	}
	
	// script source 
	NSString *scriptSource = [[script scriptCode] source];
	if (!scriptSource) {
		error = NSLocalizedString(@"Task script source is empty", @"Returned by server when task script source is empty");
		goto errorExit;	
	}
	[taskDict setObject:scriptSource forKey:MGSScriptSource];
	
	// build path
	NSString *buildPath = [script externalBuildPath];
	if (buildPath) {
		[taskDict setObject:buildPath forKey:MGSScriptBuildPath];
	}
	
	// build options
	NSString *buildOptions = [script buildOptions];
	if (buildOptions) {
		[taskDict setObject:buildOptions forKey:MGSScriptBuildOptions];
	}
	
	// we want to compile this script
	[taskDict setObject:MGSScriptActionBuild forKey:MGSScriptAction];

	return taskDict;

errorExit:
	
	if (!*mgsError) {
		*mgsError = [MGSError serverCode:MGSErrorCodeScriptBuild reason:error];
	}
	
	return nil;
}


@end

