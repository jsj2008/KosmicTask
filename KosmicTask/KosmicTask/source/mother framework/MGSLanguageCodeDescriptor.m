//
//  MGSLanguageCodeDescriptor.m
//  KosmicTask
//
//  Created by Jonathan on 07/01/2013.
//
//

#import "MGSLanguageCodeDescriptor.h"
#import "MGSLanguagePluginController.h"
#import "NSArray_Mugginsoft.h"
#import "MGSParameterPluginController.h"
#import "MGSAppController.h"
#import "MGSParameterPlugin.h"
#import "GRMustache.h"

#ifdef MGS_USE_MGTemplateEngine
#import "MGTemplateEngine/ICUTemplateMatcher.h"
#endif

char MGSScriptTypeContext;

@interface MGSLanguageCodeDescriptor()
- (MGSLanguage *)scriptLanguage;
- (NSString *)generateCodeStringFromTemplateName:(NSString *)template;
- (void)updateLanguageProperties;
- (GRMustacheTemplate *)templateName:(NSString *)name  error:(NSError **)error;

@property (assign) MGSLanguage *scriptLanguage;
@end

@implementation MGSLanguageCodeDescriptor

@synthesize functionArgumentName = _functionArgumentName;
@synthesize functionArgumentCase = _functionArgumentCase;
@synthesize functionArgumentStyle = _functionArgumentStyle;
@synthesize descriptorCodeStyle = _descriptorCodeStyle;
@synthesize script = _script;
@synthesize scriptLanguage = _scriptLanguage;

/*
 
 init
 
 */
- (id)init
{
    return [self initWithScript:nil];
}


/*
 
 initWithScript:
 
 */
- (id)initWithScript:(MGSScript *)script
{
    self = [super init];
    if (self) {
        _functionArgumentName = kMGSFunctionArgumentName;
        _functionArgumentCase = kMGSFunctionArgumentCamelCase;
        _functionArgumentStyle = kMGSFunctionArgumentWhitespaceRemoved;
        _descriptorCodeStyle = kMGSCodeDescriptorTaskInputs;
        
        if (script) {
            self.script = script;
        }
    }
    
    return self;
    
}
/*
 
 - copyFunctionArgumentsFromDescriptor:
 
 */
- (void)copyFunctionArgumentsFromDescriptor:(MGSLanguageCodeDescriptor *)descriptor
{
    self.functionArgumentCase = descriptor.functionArgumentCase;
    self.functionArgumentName = descriptor.functionArgumentName;
    self.functionArgumentStyle = descriptor.functionArgumentStyle;
    self.descriptorCodeStyle = descriptor.descriptorCodeStyle;
}

#pragma mark -
#pragma mark Code string generation

/*
 
 - generateCodeString
 
 */
- (NSString *)generateCodeString
{
    NSString *codeString = nil;
    
    @try {
        switch (self.descriptorCodeStyle) {
            case kMGSCodeDescriptorTaskInputs:

            case kMGSCodeDescriptorTaskEntry:
                codeString = [self generateTaskEntryCodeString];
                break;
                
            case kMGSCodeDescriptorTaskBody:
                codeString = [self generateTaskBodyCodeString];
               break;
                
            default:
                break;
        }
    } @catch (NSException *e) {
        NSLog(@"%@", e);
    }
    
    return codeString;
}

/*
 
 - generateTaskEntryCodeString
 
 */
- (NSString *)generateTaskEntryCodeString
{
    NSString *codeString = nil;
    
    if (self.scriptLanguage) {
        
        // look for function template
        NSString *templateName = [self.scriptLanguage taskFunctionCodeTemplateName:nil];
        
        // if no function template available then use input variables template
        if (![self templateNameExists:templateName]) {
            templateName = [self.scriptLanguage taskInputVariablesCodeTemplateName:nil];
        }
        codeString = [self generateCodeStringFromTemplateName:templateName];
    }
    
    return codeString;
}

/*
 
 - generateTaskFuctionCodeString
 
 */
- (NSString *)generateTaskFunctionCodeString
{
    NSString *codeString = nil;
    
    if (self.scriptLanguage) {
        NSString *codeTemplate = [self.scriptLanguage taskFunctionCodeTemplateName:nil];
        codeString = [self generateCodeStringFromTemplateName:codeTemplate];
    }
    
    return codeString;
}

/*
 
 - generateTaskInputsCodeString
 
 */
- (NSString *)generateTaskInputsCodeString
{
    NSString *codeString = nil;

    if (self.scriptLanguage) {
        NSString *codeTemplate = [self.scriptLanguage taskInputsCodeTemplateName:nil];
        codeString = [self generateCodeStringFromTemplateName:codeTemplate];
    }
    
    return codeString;
}

/*
 
 - generateTaskBodyCodeString
 
 */
- (NSString *)generateTaskBodyCodeString
{
    NSString *codeString = nil;

    if (self.scriptLanguage) {
        NSString *codeTemplate = [self.scriptLanguage taskBodyCodeTemplateName:nil];
        codeString = [self generateCodeStringFromTemplateName:codeTemplate];        
    }

    return codeString;
}

/*
 
 - generateCodeStringFromTemplateName:
 
 */
- (NSString *)generateCodeStringFromTemplateName:(NSString *)name
{
    NSString *codeString = nil;

    NSMutableDictionary *templateVariables = [self templateVariables];

    // run the template
    if (templateVariables) {
        NSError *error = nil;
        codeString = [self processTemplateName:name object:templateVariables error:&error];
    }

    return codeString;
}

/*
 
 - templateVariables
 
 */
- (NSMutableDictionary *)templateVariables
{
    NSArray *taskInputs = [self normalisedParameterNames:@{@"index":@(NO)}];
    NSString *taskInputsString = [self normalisedParameterNamesString];    
    NSString *functionName = @"";
    NSString *taskResult = nil;
    
    NSDictionary *codeProperties = [self.scriptLanguage codeProperties];
    NSString *inputStyle = [codeProperties objectForKey:MGSInputStyle];
    if ([inputStyle isEqualToString:@"function"]) {
        
        // format task inputs for function input style
        functionName = self.script.subroutine;
        
    }  else if ([inputStyle isEqualToString:@"variable"]) {
        
    }
    
    if ([taskInputs count] > 0) {
        taskResult = [taskInputs objectAtIndex:0];
    }
    
    // prepare template variables
    if ([taskInputs count] == 0) {
        taskInputs = nil;
    }
    NSMutableDictionary *templateVariables = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                              @"Task result", @"task-result-message", nil];
    if (taskInputs) [templateVariables setObject:taskInputs forKey:@"task-inputs"];
    if (taskInputsString) [templateVariables setObject:taskInputsString forKey:@"task-input-variables"];
    if (functionName) [templateVariables setObject:functionName forKey:@"task-function-name"];
    if (taskResult) [templateVariables setObject:taskResult forKey:@"task-result?"];

    return templateVariables;
}

#pragma mark -
#pragma mark Parameters

/*
 
 - normalisedParameterNames
 
 */
- (NSArray *)normalisedParameterNames:(NSDictionary *)options
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
        if (normalisedName) {
            [normalisedNames addObject:normalisedName];
        }
    }
 
    // make parameter names unique
    [self makeObjectsUnique:normalisedNames];

    // index the inputs
    if ([[options objectForKey:@"index"] boolValue] == YES) {

        NSString *templateName = [self.scriptLanguage taskInputCodeTemplateName:nil];

        // format inputs using template
        for (NSUInteger idx = 0; idx < [normalisedNames count]; idx++) {
            NSString *normalisedName = [normalisedNames objectAtIndex:idx];
            
            NSDictionary *variables = @{@"task-input":normalisedName, @"task-input-index-1-based?":@(idx+1), @"task-input-index-0-based?":@(idx)};
            
            NSError *error = nil;
            normalisedName = [self processTemplateName:templateName object:variables error:&error];
            
            if (normalisedName) {
                [normalisedNames replaceObjectAtIndex:idx withObject:normalisedName];
            }
        }
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
    NSString *inputTemplateName = [self.scriptLanguage taskInputCodeTemplateName:nil];
    
    // make the names unique by adding an integer identifier if name non unique
    for (NSString *key in [indexDict allKeys]) {
        NSIndexSet *indexSet = [indexDict objectForKey:key];
        if ([indexSet count] > 1) {
            NSUInteger __block identifier = 1;  // need a storage modifier
            
            [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
#pragma unused(stop)
 
                NSString *parameterName = [parameterNames objectAtIndex:idx];
                NSError *error = nil;

                // format input using template
                parameterName = [self processTemplateName:inputTemplateName object:@{@"task-input":parameterName, @"task-input-id?":@(identifier)} error:&error];
                
                // re normalise using the parameter name but don't do case processing
                // this time around
                MGSFunctionArgumentCase argumentCase = self.functionArgumentCase;
                _functionArgumentCase = kMGSFunctionArgumentInputCase;
                parameterName = [self normalisedParameterName:parameterName];
                _functionArgumentCase = argumentCase;

                if (parameterName) {
                    [parameterNames replaceObjectAtIndex:idx withObject:parameterName];
                }
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
    NSArray *taskInputsList = [self normalisedParameterNames:@{@"index":@(YES)}];

    NSMutableArray *taskInputs = nil;
    
    if ([taskInputsList count] > 0) {
        taskInputs = [NSMutableArray arrayWithCapacity:[taskInputsList count]];
        for (NSUInteger idx = 0; idx < [taskInputsList count]; idx++) {
            NSString *taskInput = [taskInputsList objectAtIndex:idx];
            NSMutableDictionary *taskInputDict = [NSMutableDictionary dictionaryWithCapacity:2];
            [taskInputDict setObject:taskInput forKey:@"task-input"];
            
            if (idx == [taskInputsList count] - 1) {
                [taskInputDict setObject:@(YES) forKey:@"last-item?"];
            }
            [taskInputs addObject:taskInputDict];
            
        }
    } else {
        taskInputsList = nil;
        
    }
    
    NSString *templateName = [self.scriptLanguage taskInputsCodeTemplateName:nil];

    NSError *error = nil;
    NSMutableDictionary *templateVariables = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                              @"No task inputs defined", @"task-inputs-message", nil];
    if (taskInputsList) [templateVariables setObject:taskInputsList forKey:@"task-inputs-list"];
    if (taskInputs) [templateVariables setObject:taskInputs forKey:@"task-inputs"];
    
    NSString *nameString = [self processTemplateName:templateName object:templateVariables error:&error];

 /*
*/
/*
    // apply template separator
    for (NSUInteger idx = 0; idx < [taskInputsList count]; idx++) {
        NSString *taskInput = [taskInputsList objectAtIndex:idx];
        
        // apply separator template too all inputs except the last one
        if (idx < [taskInputsList count] - 1) {
            taskInput = [self processTemplate:separatorTemplateName object:@{@"task-input":taskInput} error:NULL];
         }
        [nameString appendString:taskInput];

    }
*/
    
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
    
    // get the template repository.
    // we need to access templates from the repository if our templates include partials (references to other templates)
    NSString *templateRepositoryPath = [self.scriptLanguage codeTemplateResourcePath];
    _templateRepository = [GRMustacheTemplateRepository templateRepositoryWithDirectory:templateRepositoryPath
                                                                      templateExtension:@"mustache"
                                                                               encoding:NSUTF8StringEncoding];
    
    if (!_templateRepository) {
        MLogInfo(@"Code template repository not found at %@", templateRepositoryPath);
    }

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

#pragma mark -
#pragma mark Template processing

/*
 
 - processTemplate:object:error
 
 */
/*
- (NSString *)processTemplate:(NSString *)template object:(NSDictionary *)variables error:(NSError **)error
{
    BOOL raise = NO;
    NSString *output = nil;
    if (error != NULL) {
        *error = nil;
    }
    
    NSUInteger templateEngine = 1;
    
    switch (templateEngine) {
        case 0:

#ifdef MGS_USE_MGTemplateEngine
            
            // configure the template engine
            if (!_templateEngine) {
                _templateEngine = [MGTemplateEngine templateEngine];
                //[_templateEngine setDelegate:self];
                [_templateEngine setMatcher:[ICUTemplateMatcher matcherWithTemplateEngine:_templateEngine]];
            }
            
            output = [_templateEngine processTemplate:template withVariables:variables];
#endif
            break;
            
            ///
             
            // GRMustache is much more capable and includes tests.
             
             //
        case 1:
            // render template string
            output = [GRMustacheTemplate renderObject:variables
                                           fromString:template
                                                error:error];
            
            if (error != NULL && *error) {
                if (raise) {
                    [NSException raise:@"Code template exception" format:@"Template error : %@", *error];
                } else {
                    MLogInfo(@"Code template error: %@", *error);
                    output = nil;
                }
            }

            break;
            
    }
    
    return output;
}
*/

/*
 
 - processTemplateName:object:error
 
 */
- (NSString *)processTemplateName:(NSString *)name object:(NSDictionary *)variables error:(NSError **)error
{
    NSString *output = nil;
    
    if (error != NULL) {
        *error = nil;
    }
    
    // input is a template name.
    GRMustacheTemplate *template = [self templateName:name error:error];
    if (!template) {
        return output;
    }
    
    // render object
    output = [template renderObject:variables error:error];
    
    // if caller does not receive error info then log simple error
    if (error == NULL && !output) {
        MLogInfo(@"Template process error: %@ %@", self.script.scriptType, name);
    }
    
    return output;
}

/*
 
 - templateName:error:
 
 */
- (GRMustacheTemplate *)templateName:(NSString *)name  error:(NSError **)error
{
    if (error != NULL) {
        *error = nil;
    }
    
    // input is a template name.
    // acessing the template via the repository means that partials can be called
    GRMustacheTemplate *template = [_templateRepository templateNamed:name error:error];
    if (error == NULL && !template) {
        MLogInfo(@"Code template name error: %@ %@", self.script.scriptType, name);
    }
    
    return template;
}

/*
 
 - templateNameExists:
 
 */
- (BOOL)templateNameExists:(NSString *)name
{
    NSError *error = nil;
    BOOL exists = [self templateName:name error:&error] != nil ? YES : NO;
    
    return exists;
}
@end
