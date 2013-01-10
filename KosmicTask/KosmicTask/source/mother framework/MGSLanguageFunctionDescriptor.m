//
//  MGSLanguageFunctionDescriptor.m
//  KosmicTask
//
//  Created by Jonathan on 07/01/2013.
//
//

#import "MGSLanguageFunctionDescriptor.h"
#import "MGSLanguagePluginController.h"
#import "NSArray_Mugginsoft.h"
#import "MGTemplateEngine/ICUTemplateMatcher.h"
#import "MGSParameterPluginController.h"
#import "MGSAppController.h"
#import "MGSParameterPlugin.h"

char MGSScriptTypeContext;

@interface MGSLanguageFunctionDescriptor()
- (MGSLanguage *)scriptLanguage;
- (NSString *)generateCodeStringFromTemplate:(NSString *)template;
- (void)updateLanguageProperties;

@property (assign) MGSLanguage *scriptLanguage;
@end

@implementation MGSLanguageFunctionDescriptor

@synthesize functionArgumentName = _functionArgumentName;
@synthesize functionArgumentCase = _functionArgumentCase;
@synthesize functionArgumentStyle = _functionArgumentStyle;
@synthesize functionCodeStyle = _functionCodeStyle;
@synthesize script = _script;
@synthesize scriptLanguage = _scriptLanguage;

/*
 
 init
 
 */
- (id)init
{
    self = [super init];
    if (self) {
        _functionArgumentName = kMGSFunctionArgumentName;
        _functionArgumentCase = kMGSFunctionArgumentCamelCase;
        _functionArgumentStyle = kMGSFunctionArgumentWhitespaceRemoved;
        _functionCodeStyle = kMGSFunctionCodeTaskInputs;
        
        // configure the template engine
        _templateEngine = [MGTemplateEngine templateEngine];
        //[_templateEngine setDelegate:self];
        [_templateEngine setMatcher:[ICUTemplateMatcher matcherWithTemplateEngine:_templateEngine]];
    }
    
    return self;
}

/*
 
 - copyFunctionArgumentsFromDescriptor:
 
 */
- (void)copyFunctionArgumentsFromDescriptor:(MGSLanguageFunctionDescriptor *)descriptor
{
    self.functionArgumentCase = descriptor.functionArgumentCase;
    self.functionArgumentName = descriptor.functionArgumentName;
    self.functionArgumentStyle = descriptor.functionArgumentStyle;
    self.functionCodeStyle = descriptor.functionCodeStyle;
}

#pragma mark -
#pragma mark Code string generation

/*
 
 - generateCodeString
 
 */
- (NSString *)generateCodeString
{
    NSString *codeString = nil;
    
    switch (self.functionCodeStyle) {
        case kMGSFunctionCodeTaskInputs:
            codeString = [self generateTaskInputsCodeString];
            break;
            
        case kMGSFunctionCodeTaskBody:
            codeString = [self generateTaskBodyCodeString];
           break;
            
        default:
            codeString = @"[invalid]";
            break;
    }
    
    return codeString;
}

/*
 
 - generateTaskInputsCodeString
 
 */
- (NSString *)generateTaskInputsCodeString
{
    NSString *codeString = @"[task inputs code not available]";

    if (self.scriptLanguage) {
        NSString *codeTemplate = [self.scriptLanguage taskInputsCodeTemplate:nil];
        codeString = [self generateCodeStringFromTemplate:codeTemplate];
    }
    
    return codeString;
}

/*
 
 - generateTaskBodyCodeString
 
 */
- (NSString *)generateTaskBodyCodeString
{
    NSString *codeString = @"[task body code not available]";

    if (self.scriptLanguage) {
        NSString *codeTemplate = [self.scriptLanguage taskBodyCodeTemplate:nil];
        codeString = [self generateCodeStringFromTemplate:codeTemplate];        
    }

    return codeString;
}

/*
 
 - generateCodeStringFromTemplate:
 
 */
- (NSString *)generateCodeStringFromTemplate:(NSString *)template
{
    NSString *codeString = @"[code not available]";

    
    NSArray *taskInputsList = [self normalisedParameterNames];
    NSString *taskInputs = [self normalisedParameterNamesString];
    NSString *functionName = @"";
    
    NSDictionary *codeProperties = [self.scriptLanguage codeProperties];
    NSString *inputStyle = [codeProperties objectForKey:MGSInputStyle];
    if ([inputStyle isEqualToString:@"function"]) {
        
        // format task inputs for function input style
        functionName = self.script.subroutine;
        
    }  else if ([inputStyle isEqualToString:@"variable"]) {
        
    }
    // prepare template variables
    if (!taskInputs) taskInputs = @"";
    if (!functionName) functionName = @"";
    if (!taskInputsList) taskInputsList = [NSArray new];
    NSDictionary *templateVariables = @{@"task-function":functionName, @"task-inputs":taskInputs, @"task-inputs-list":taskInputsList};

    // run the template
    if (templateVariables) {
        codeString = [_templateEngine processTemplate:template withVariables:templateVariables];
    }

    return codeString;
}
#pragma mark -
#pragma mark Parameters

/*
 
 - normalisedParameterNames
 
 */
- (NSArray *)normalisedParameterNames
{
    MGSScriptParameterManager *parameterManager = self.script.parameterHandler;
    NSUInteger parameterCount = [parameterManager count];
    
    MGSParameterPluginController *parameterPluginController = [[NSApp delegate] parameterPluginController];
    // build array of normalised parameter names
    NSMutableArray *normalisedNames  = [NSMutableArray arrayWithCapacity:parameterCount];
    for (NSUInteger i = 0; i < parameterCount; i++) {
        MGSScriptParameter *parameter = [parameterManager itemAtIndex:i];
        MGSParameterPlugin *parameterPlugin = [parameterPluginController pluginWithClassName:[parameter typeName]];
        NSString *parameterName = [parameterPlugin menuItemString];
        if (!parameterName) {
            parameterName = @"missing";
        }
        NSString *normalisedName = [self normalisedParameterName:[parameter name] typeName:parameterName];
        [normalisedNames addObject:normalisedName];
    }
 
    // make parameter names unique
    [self makeObjectsUnique:normalisedNames];

    // format inputs using template
    NSString *inputTemplate = [self.scriptLanguage taskInputCodeTemplate:nil];
    for (NSUInteger idx = 0; idx < parameterCount; idx++) {
        NSString *normalisedName = [normalisedNames objectAtIndex:idx];
        normalisedName = [_templateEngine processTemplate:inputTemplate
                                            withVariables:@{@"task-input":normalisedName, @"task-input-index-1-based":@(idx+1), @"task-input-index-0-based":@(idx)}];
        [normalisedNames replaceObjectAtIndex:idx withObject:normalisedName];
    }
    
    return normalisedNames;
}

/*
 
 - makeObjectsUnique:
 
 */
- (void)makeObjectsUnique:(NSMutableArray *)parameterNames
{
    // get dictionary of object indexes
    NSDictionary *indexDict = [parameterNames mgs_objectIndexes];
    NSString *inputTemplate = [self.scriptLanguage taskInputDuplicateCodeTemplate:nil];
    
    // make the names unique by adding an integer identifier if name non unique
    for (NSString *key in [indexDict allKeys]) {
        NSIndexSet *indexSet = [indexDict objectForKey:key];
        if ([indexSet count] > 1) {
            NSUInteger __block identifier = 1;  // need a storage modifier
            
            [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
#pragma unused(stop)
 
                NSString *parameterName = [parameterNames objectAtIndex:idx];
                
                // format input using template
                parameterName = [_templateEngine processTemplate:inputTemplate withVariables:@{@"task-input":parameterName, @"task-input-id":@(identifier)}];
                
                // re normalise using the parameter name but don't do case processing
                // this time around
                MGSFunctionArgumentCase argumentCase = self.functionArgumentCase;
                _functionArgumentCase = kMGSFunctionArgumentInputCase;
                parameterName = [self normalisedParameterName:parameterName];
                _functionArgumentCase = argumentCase;

                [parameterNames replaceObjectAtIndex:idx withObject:parameterName];
                identifier++;
            }];
        }
    }
}
/*
 
 - normalisedParameterNamesString
 
 */
- (NSString *)normalisedParameterNamesString
{
    NSArray *taskInputsList = [self normalisedParameterNames];    
    NSMutableString *nameString = [NSMutableString new];

    
    // apply template separator
    NSString *separatorTemplate = [self.scriptLanguage taskInputSeparatorCodeTemplate:nil];
    for (NSUInteger idx = 0; idx < [taskInputsList count]; idx++) {
        NSString *taskInput = [taskInputsList objectAtIndex:idx];
        
        // apply separator template too all inputs excpet the last one
        if (idx < [taskInputsList count] - 1) {
            taskInput = [_templateEngine processTemplate:separatorTemplate withVariables:@{@"task-input":taskInput, @"input-index-1-based":@(idx+1), @"input-index-0-based":@(idx)}];
         }
        [nameString appendString:taskInput];

    }
    
    return nameString;
}

/*
 
 - normalisedParameterName:typeName:
 
 */
- (NSString *)normalisedParameterName:(NSString *)name typeName:(NSString *)typeName
{
    NSString *normalisedName = nil;
    
    // cleanup input strings
    name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    typeName = [typeName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    // order argument name elements
    switch (self.functionArgumentName) {
        
        case kMGSFunctionArgumentName:
        default:
            normalisedName = name;
            break;
            
        case kMGSFunctionArgumentNameAndType:
            normalisedName = [NSString stringWithFormat:@"%@ %@", name, typeName];
            break;
            
        case kMGSFunctionArgumentType:
            normalisedName = typeName;
            break;
            
        case kMGSFunctionArgumentTypeAndName:
            normalisedName = [NSString stringWithFormat:@"%@ %@", typeName, name];
           break;
    }
    
    normalisedName = [self normalisedParameterName:normalisedName];
    
    return normalisedName;
}

/*
 
 - normalisedParameterName:
 
 */
- (NSString *)normalisedParameterName:(NSString *)name 
{
    // cleanup input strings
    name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    // mutate argument case
    SEL firstArgumentSelector = NULL;
    SEL argumentSelector = NULL;
    
    switch (self.functionArgumentCase) {
            
        case kMGSFunctionArgumentCamelCase:
            firstArgumentSelector = @selector(lowercaseString);
            argumentSelector = @selector(capitalizedString);
            break;
            
        case kMGSFunctionArgumentLowerCase:
            argumentSelector = @selector(lowercaseString);
            break;
            
        case kMGSFunctionArgumentInputCase:
        default:
            break;
            
        case kMGSFunctionArgumentPascalCase:
            argumentSelector = @selector(capitalizedString);
            break;
            
        case kMGSFunctionArgumentUpperCase:
            argumentSelector = @selector(uppercaseString);
            break;
    }
    
    NSMutableArray *nameComponents = [NSMutableArray arrayWithArray:[name componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    
    NSArray *nameComponentsCopy = [nameComponents copy];
    for (NSUInteger i = 0; i < [nameComponentsCopy count]; i++) {
        NSString *nameComponent  = [nameComponentsCopy objectAtIndex:i];
        SEL sel = argumentSelector;
        if (i == 0) {
            if (firstArgumentSelector) {
                sel = firstArgumentSelector;
            }
        }
        if (sel) {
            nameComponent = [nameComponent performSelector:sel];
            [nameComponents replaceObjectAtIndex:i withObject:nameComponent];
        }
    }
    
    // style arguments
    NSString *joinString = nil;
    switch (self.functionArgumentStyle) {
        case kMGSFunctionArgumentHyphenated:
            joinString = @"-";
            break;
            
        case kMGSFunctionArgumentUnderscoreSeparated:
            joinString = @"_";
            break;
            
        case kMGSFunctionArgumentWhitespaceRemoved:
        default:
            joinString = @"";
            break;
    }
    
    NSString *normalisedName = [nameComponents componentsJoinedByString:joinString];

    return normalisedName;
}


#pragma mark -
#pragma mark Accessors

/*
 
 - setScript
 
 */
- (void)setScript:(MGSScript *)script
{
    if (_script) {
        [_script removeObserver:self forKeyPath:@"scriptType"];
    }
    _script = script;
    [self updateLanguageProperties];
    [_script addObserver:self forKeyPath:@"scriptType" options:0 context:&MGSScriptTypeContext];
}

/*
 
 - updateLanguageProperties
 
 */
- (void)updateLanguageProperties
{
    MGSLanguage *language = nil;
    
    // get the plugin
    MGSLanguagePlugin *languagePlugin = [[MGSLanguagePluginController sharedController] pluginWithScriptType:_script.scriptType];
    
    if (languagePlugin) {
        
        // get language
        language = [[languagePlugin languageClass] new];
    }
    self.scriptLanguage = language;
}

#pragma mark -
#pragma mark KVO

/*
 
 - observeValueForKeyPath:ofObject:change:context:
 
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
#pragma unused(keyPath)
#pragma unused(object)
#pragma unused(change)
    
    if (context == &MGSScriptTypeContext) {
        [self updateLanguageProperties];
    }
}
@end
