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

#ifdef MGS_USE_MGTemplateEngine
#import "MGTemplateEngine/ICUTemplateMatcher.h"
#endif

char MGSScriptTypeContext;

@interface MGSLanguageCodeDescriptor()
- (MGSLanguage *)scriptLanguage;
- (NSString *)generateCodeStringFromTemplateName:(NSString *)template;
- (void)updateLanguageProperties;
- (GRMustacheTemplate *)templateName:(NSString *)name  error:(NSError **)error;
- (NSString *)templateErrorString:(NSError *)error;
- (id)normalizeTemplateVariable:(id)inputObject;
- (void)addDefaultTemplateVariables:(NSMutableDictionary *)templateVariables;
- (NSMutableDictionary *)templateTaskInfo;

@property (assign) MGSLanguage *scriptLanguage;
@property (assign) MGSTemplateObjectRendering templateObjectRendering;
@end

@implementation MGSLanguageCodeDescriptor

@synthesize inputArgumentName = _inputArgumentName;
@synthesize inputArgumentCase = _inputArgumentCase;
@synthesize inputArgumentStyle = _inputArgumentStyle;
@synthesize descriptorCodeStyle = _descriptorCodeStyle;
@synthesize script = _script;
@synthesize scriptLanguage = _scriptLanguage;
@synthesize inputArgumentPrefix = _inputArgumentPrefix;
@synthesize inputArgumentNameExclusions = _inputArgumentNameExclusions;
@synthesize templateObjectRendering = _templateObjectRendering;

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
        _inputArgumentName = kMGSInputArgumentName;
        _inputArgumentCase = kMGSInputArgumentCamelCase;
        _inputArgumentStyle = kMGSInputArgumentWhitespaceRemoved;
        _descriptorCodeStyle = kMGSCodeDescriptorTaskInputs;
        _inputArgumentPrefix = @"";
        _inputArgumentNameExclusions = @"";
        _templateObjectRendering = MGSTemplateObjectRenderingDefault;
        
        if (script) {
            self.script = script;
        }
    }
    
    return self;
    
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
        
        NSString *templateName = nil;
        
        eMGSOnRunTask onRun = [self.script.onRun integerValue];

        switch(onRun) {
                
            // look for class function template
            case kMGSOnRunCallClassFunction:
                templateName = [self.scriptLanguage taskClassFunctionCodeTemplateName:self.templateTaskInfo];
                if (templateName) {
                    break;
                }
                // fall through
                
            // look for function template
            case kMGSOnRunCallScriptFunction:
                templateName = [self.scriptLanguage taskFunctionCodeTemplateName:self.templateTaskInfo];
                break;

            default:
                break;
        }
        
        // if no function template available then use input variables
        if (![self templateNameExists:templateName]) {            
            NSMutableDictionary *templateVariables = [self generateTemplateVariables];
            codeString = [templateVariables objectForKey:@"task-input-variables"];
        } else {
            codeString = [self generateCodeStringFromTemplateName:templateName];
        }
    }
    
    return codeString;
}

/*
 
 - generateTaskEntryPatternString
 
 */
- (NSString *)generateTaskEntryPatternString
{
    NSString *patternString = nil;
    
    if (self.scriptLanguage) {
        
        NSString *templateName = nil;
        BOOL codeTemplateLoaded = NO;
        
        // set the template object rendering mode to regex pattern
        MGSTemplateObjectRendering templateObjectRenderingTemp = self.templateObjectRendering;
        self.templateObjectRendering = MGSTemplateObjectRenderingRegexPattern;
        
        eMGSOnRunTask onRun = [self.script.onRun integerValue];
        
        // logic
        // use a pattern template if if exists.
        // if not use a code template and refactor into a simple pattern.
        // this should give default task entry matching.
        // for better matching performance (eg: better whitespace tolerance) custom
        // patterns can be defined.
        switch(onRun) {
                
                // look for class function pattern template
            case kMGSOnRunCallClassFunction:
                
                // get valid pattern template
                templateName = [self.scriptLanguage taskClassFunctionPatternTemplateName:self.templateTaskInfo];
                if (![self templateNameExists:templateName]) break;
                
                // get valid code template
                templateName = [self.scriptLanguage taskClassFunctionCodeTemplateName:self.templateTaskInfo];
                if ([self templateNameExists:templateName]) {
                    codeTemplateLoaded = YES;
                    break;
                }
                
                // fall through
                
                // look for function pattern template
            case kMGSOnRunCallScriptFunction:
                
                // pattern
                templateName = [self.scriptLanguage taskFunctionPatternTemplateName:self.templateTaskInfo];
                if ([self templateNameExists:templateName]) break;
                
                // code
                templateName = [self.scriptLanguage taskFunctionCodeTemplateName:self.templateTaskInfo];
                if ([self templateNameExists:templateName]) {
                    codeTemplateLoaded = YES;
                }
                break;
                
            default:
                // generate task inputs pattern
                templateName = [self.scriptLanguage taskInputsPatternTemplateName:self.templateTaskInfo];
                
                // code
                if (![self templateNameExists:templateName]) {
                    templateName = [self.scriptLanguage taskInputsCodeTemplateName:self.templateTaskInfo];
                    codeTemplateLoaded = YES;
                }
                patternString = [self normalisedParameterNamesStringWithTemplateName:templateName];
                
                break;
        }
        
        // generate pattern from template
        if ([self templateNameExists:templateName] && !patternString) {
            patternString = [self generateCodeStringFromTemplateName:templateName];
        }

        self.templateObjectRendering = templateObjectRenderingTemp;

        // use code template to build a simple pattern
        if (codeTemplateLoaded) {
            // escape the code to disable pattern metacharaters
            patternString = [NSRegularExpression escapedPatternForString:patternString];
            
            // the idea was to add ^ and $ to the pattern but there are cases,
            // such as F-script, where a match to the beginning and end of the line is perhaps not desired.
            patternString = [NSString stringWithFormat:@"%@", patternString];
        }
        
        MLogInfo(@"patternString = %@", patternString);
    }
    return patternString;
}

/*
 
 - generateTaskFuctionCodeString
 
 */
- (NSString *)generateTaskFunctionCodeString
{
    NSString *codeString = nil;
    
    if (self.scriptLanguage) {
        
        NSDictionary *codeProperties = [self.scriptLanguage codeProperties];
        NSString *inputStyle = [codeProperties objectForKey:MGSInputStyle];
        
        // script must support function inputs
        if ([inputStyle isEqualToString:@"function"]) {
            NSString *codeTemplate = [self.scriptLanguage taskFunctionCodeTemplateName:self.templateTaskInfo];
            codeString = [self generateCodeStringFromTemplateName:codeTemplate];
        }
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
        NSString *codeTemplate = [self.scriptLanguage taskInputsCodeTemplateName:self.templateTaskInfo];
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
        
        NSString *codeTemplate = [self.scriptLanguage taskBodyCodeTemplateName:self.templateTaskInfo];
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

    NSMutableDictionary *templateVariables = [self generateTemplateVariables];

    // run the template
    if (templateVariables) {
        NSError *error = nil;
        codeString = [self processTemplateName:name object:templateVariables error:&error];
        if (error) {
            codeString = [self templateErrorString:error];
        }
    }

    return codeString;
}

/*
 
 - templateTaskInfo
 
 */
- (NSMutableDictionary *)templateTaskInfo
{
    // build the task info
    NSMutableDictionary *taskInfo = [NSMutableDictionary dictionaryWithCapacity:5];
    if (self.script.onRun) {
        [taskInfo setObject:self.script.onRun forKey:@"onRun"];
    }

    return taskInfo;
}

#pragma mark
#pragma mark Template variables
/*
 
 - generateTemplateVariables
 
 */
- (NSMutableDictionary *)generateTemplateVariables
{
    NSError *error = nil;
    
    // generate task inputs
    NSArray *taskInputs = [self normalisedParameterNames:@{@"index":@(NO)}];
    NSString *templateName = [self.scriptLanguage taskInputsCodeTemplateName:self.templateTaskInfo];
    NSString *taskInputsString = [self normalisedParameterNamesStringWithTemplateName:templateName];

    if ([taskInputs count] == 0) {
        taskInputs = nil;
    } else {
        taskInputs = [self normalizeTemplateVariable:taskInputs];
    }
    
    // update script parameters with input values
    for (NSUInteger i = 0; i < [taskInputs count]; i++) {
        NSDictionary *taskInput = [taskInputs objectAtIndex:i];
        NSString *inputName = [taskInput objectForKey:@"name"];
        if (!inputName) inputName = @"missing";
        
        if (i < (NSUInteger)_script.parameterHandler.count) {
            MGSScriptParameter *scriptParameter = [_script.parameterHandler itemAtIndex:i];
            
            // update the script variable name in auto mode
            if (scriptParameter.variableNameUpdating == MGSScriptParameterVariableNameUpdatingAuto) {
                scriptParameter.variableName = inputName;
            }
        }
    }
    

    // query class properties
    NSString *functionName = nil;
    NSString *runClassName = nil;

    NSDictionary *codeProperties = [self.scriptLanguage codeProperties];
    NSString *inputStyle = [codeProperties objectForKey:MGSInputStyle];
    if ([inputStyle isEqualToString:@"function"]) {
        
        // format task inputs for function input style
        functionName = self.script.subroutine;
        
    }  else if ([inputStyle isEqualToString:@"variable"]) {
        
    }

    runClassName = self.script.runClass;
    if ([runClassName length] == 0) {
        runClassName = nil;
    }
    
    // define template variables dictionary
    NSMutableDictionary *templateVariables = [NSMutableDictionary dictionaryWithCapacity:15];
    if (taskInputs) [templateVariables setObject:taskInputs forKey:@"task-inputs"];
    if (taskInputsString) [templateVariables setObject:taskInputsString forKey:@"task-input-variables"];
    if (functionName) [templateVariables setObject:functionName forKey:@"task-function-name"];
    if (runClassName) [templateVariables setObject:runClassName forKey:@"task-class-name"];
    [self addDefaultTemplateVariables:templateVariables];

    // add task input result key
    templateName = [self.scriptLanguage taskInputResultCodeTemplateName:self.templateTaskInfo];
    if ([self templateNameExists:templateName]) {
        NSString *taskInputResult = [self processTemplateName:templateName object:templateVariables error:&error];
        if (error) {
            taskInputResult = [self templateErrorString:error];
        }
        if (taskInputResult) [templateVariables setObject:taskInputResult forKey:@"task-input-result"];

    }

    // add task header key
    templateName = [self.scriptLanguage taskHeaderCodeTemplateName:self.templateTaskInfo];
    if ([self templateNameExists:templateName]) {
        NSString *taskHeader = [self processTemplateName:templateName object:templateVariables error:&error];
        if (error) {
            taskHeader = [self templateErrorString:error];
        }
        if (taskHeader) [templateVariables setObject:taskHeader forKey:@"task-header"];
        
    }

    // add task input conditional key
    templateName = [self.scriptLanguage taskInputConditionalCodeTemplateName:self.templateTaskInfo];
    if ([self templateNameExists:templateName]) {
        NSString *taskHeader = [self processTemplateName:templateName object:templateVariables error:&error];
        if (error) {
            taskHeader = [self templateErrorString:error];
        }
        if (taskHeader) [templateVariables setObject:taskHeader forKey:@"task-input-conditional"];        
    }

    // add task class function key
    templateName = [self.scriptLanguage taskClassFunctionCodeTemplateName:self.templateTaskInfo];
    if ([self templateNameExists:templateName]) {
        NSString *taskHeader = [self processTemplateName:templateName object:templateVariables error:&error];
        if (error) {
            taskHeader = [self templateErrorString:error];
        }
        if (taskHeader) [templateVariables setObject:taskHeader forKey:@"task-class-function"];
    }

    return templateVariables;
}

/*
 
 - addDefaultTemplateVariables:
 
 */
- (void)addDefaultTemplateVariables:(NSMutableDictionary *)templateVariables
{
    // string sthat will be matched as aprt of a replacement pattern must begin
    // and end with _
    NSString *taskEntryMessage = NSLocalizedString(@"Task entry point", @"Task entry point message");
    NSString *taskCodeMessage = NSLocalizedString(@"Enter task code here", @"Task code message");
    NSString *taskInputResultMessage = NSLocalizedString(@"Return inputs as task result", @"Task input result message");
    NSString *taskFormResultMessage = NSLocalizedString(@"Form task result", @"Task form result message");
    NSString *taskDefaultResult = NSLocalizedString(@"Default task result", @"Task default result");
    NSString *taskInputVariablesMessage = NSLocalizedString(@"_Task input variables_", @"Task input variables message");    // mark pattern
    NSString *taskInputsMissingMessage = NSLocalizedString(@"_No task inputs defined_", @"No task inputs defined message"); // mark pattern
    NSString *taskNewLine = NSLocalizedString(@"\n", @"Task new line");
    NSString *taskNewLineX2 = NSLocalizedString(@"\n\n", @"Task new line x 2");
    NSString *taskTab = NSLocalizedString(@"\t", @"Task tab");
    NSString *taskTabX2 = NSLocalizedString(@"\t\t", @"Task tab x 2");
    NSString *taskTabX3 = NSLocalizedString(@"\t\t\t", @"Task tab x 3");
    NSString *author = [MGSScript defaultAuthor];
    NSString *script = self.script.scriptType;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:kCFDateFormatterShortStyle];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    NSString *date = [dateFormatter stringFromDate:[NSDate date]];

    if (taskEntryMessage) [templateVariables setObject:taskEntryMessage forKey:@"task-entry-message"];
    if (taskCodeMessage) [templateVariables setObject:taskCodeMessage forKey:@"task-code-message"];
    if (taskInputResultMessage) [templateVariables setObject:taskInputResultMessage forKey:@"task-input-result-message"];
    if (taskFormResultMessage) [templateVariables setObject:taskFormResultMessage forKey:@"task-form-result-message"];
    if (taskDefaultResult) [templateVariables setObject:taskDefaultResult forKey:@"task-default-result"];
    if (taskInputVariablesMessage) [templateVariables setObject:taskInputVariablesMessage forKey:@"task-input-variables-message"];
    if (taskInputsMissingMessage) [templateVariables setObject:taskInputsMissingMessage forKey:@"task-inputs-undefined-message"];
    if (taskNewLine) [templateVariables setObject:taskNewLine forKey:@"eol"];
    if (taskNewLineX2) [templateVariables setObject:taskNewLineX2 forKey:@"eol2"];
    if (taskTab) [templateVariables setObject:taskTab forKey:@"tab"];
    if (taskTabX2) [templateVariables setObject:taskTabX2 forKey:@"tab2"];
    if (taskTabX3) [templateVariables setObject:taskTabX3 forKey:@"tab3"];
    if (author) [templateVariables setObject:author forKey:@"author"];
    if (script) [templateVariables setObject:script forKey:@"script"];
    if (date) [templateVariables setObject:date forKey:@"date"];
    
}

/*
 
 - normalizeTemplateVariable:
 
 */
- (id)normalizeTemplateVariable:(id)inputObject
{
    id outputObject = nil;
    
    if ([inputObject isKindOfClass:[NSArray class]]) {
        
        NSArray *inputArray = inputObject;
        NSMutableArray *outputArray = [NSMutableArray arrayWithCapacity:[inputArray count]];
        for (NSUInteger i = 0; i < [inputArray count]; i++) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:5];
            [dict setObject:[inputArray objectAtIndex:i] forKey:@"name"];
            [dict setObject:@(i) forKey:@"index-0"];
            [dict setObject:@(i+1) forKey:@"index-1"];
            if ((i + 1) % 2 == 0) {
                [dict setObject:@"yes" forKey:@"even"];
            } else {
                [dict setObject:@"yes" forKey:@"odd"];
            }
            if (i == 0) {
                [dict setObject:@"yes" forKey:@"first"];
            }
            if (i == ([inputArray count] - 1)) {
                [dict setObject:@"yes" forKey:@"last"];
            }
            [outputArray addObject:dict];
        }
        
        outputObject = outputArray;
    } else {
        outputObject = inputObject;
    }
         
    return outputObject;
}
#pragma mark -
#pragma mark Error Handling

/*
 
 - templateErrorString:
 
 */
- (NSString *)templateErrorString:(NSError *)error
{
    NSString *string = @"";
    if (error) {
        string = [NSString stringWithFormat:@"Template error : %@", [error  localizedDescription]];
    }
    return string;
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
        
        // get current parameter
        MGSScriptParameter *parameter = [parameterManager itemAtIndex:i];
        NSString *normalisedName = nil;
        
        // is this parameter to be auto generated ?
        // new parameters are auto generated by default.
        if (parameter.variableNameUpdating == MGSScriptParameterVariableNameUpdatingAuto) {
            MGSParameterPlugin *parameterPlugin = [parameterPluginController pluginWithClassName:[parameter typeName]];
            NSString *parameterName = [parameterPlugin menuItemString];
            if (!parameterName) {
                parameterName = @"missing";
            }
            normalisedName = [self normalisedParameterName:[parameter name] typeName:parameterName];
            
        } else {
            
            // use existing variable name for parameter.
            // we don't want to auto generate by default as it tends to break scripts.
            normalisedName = parameter.variableName;
        }
        
        // add to normalised name array
        if (normalisedName) {
            [normalisedNames addObject:normalisedName];
        }
    }
 
    // make parameter names unique
    [self makeObjectsUnique:normalisedNames];

    // index the inputs
    if ([[options objectForKey:@"index"] boolValue] == YES) {

        NSString *templateName = [self.scriptLanguage taskInputCodeTemplateName:self.templateTaskInfo];

        // format inputs using template
        for (NSUInteger idx = 0; idx < [normalisedNames count]; idx++) {
            NSString *normalisedName = [normalisedNames objectAtIndex:idx];
            
            // build template variables
            NSMutableDictionary *templateVariables = [NSMutableDictionary dictionaryWithCapacity:10];
            [templateVariables setObject:normalisedName forKey:@"name"];
            [templateVariables setObject:@(idx+1) forKey:@"index-1"];
            [templateVariables setObject:@(idx) forKey:@"index-0"];
            [self addDefaultTemplateVariables:templateVariables];
            
            NSError *error = nil;
            normalisedName = [self processTemplateName:templateName object:templateVariables error:&error];
            if (error) {
                normalisedName = [self templateErrorString:error];
            }

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
    NSString *inputTemplateName = [self.scriptLanguage taskInputNameCodeTemplateName:self.templateTaskInfo];
    
    // make the names unique by adding an integer identifier if name non unique
    for (NSString *key in [indexDict allKeys]) {
        NSIndexSet *indexSet = [indexDict objectForKey:key];
        if ([indexSet count] > 1) {
            NSUInteger __block identifier = 1;  // need a storage modifier
            
            [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
#pragma unused(stop)
 
                NSString *parameterName = [parameterNames objectAtIndex:idx];
                NSError *error = nil;

                // build template variables
                NSMutableDictionary *templateVariables = [NSMutableDictionary dictionaryWithCapacity:10];
                [templateVariables setObject:parameterName forKey:@"name"];
                [templateVariables setObject:@(identifier) forKey:@"index-1"];
                [templateVariables setObject:@(identifier - 1) forKey:@"index-0"];
                [self addDefaultTemplateVariables:templateVariables];

                // format input using template
                parameterName = [self processTemplateName:inputTemplateName object:templateVariables error:&error];
                if (error) {
                    parameterName = [self templateErrorString:error];
                }
                
                // re normalise using the parameter name but don't do case processing
                // or prefixing this time around
                MGSInputArgumentCase argumentCase = self.inputArgumentCase;
                NSString *argumentPrefix = self.inputArgumentPrefix;
                _inputArgumentCase = kMGSInputArgumentInputCase;
                _inputArgumentPrefix = nil;
                parameterName = [self normalisedParameterName:parameterName];
                _inputArgumentCase = argumentCase;
                _inputArgumentPrefix = argumentPrefix;
                
                if (parameterName) {
                    [parameterNames replaceObjectAtIndex:idx withObject:parameterName];
                }
                identifier++;
            }];
        }
    }
}
/*
 
 - normalisedParameterNamesStringWithTemplateName:
 
 */
- (NSString *)normalisedParameterNamesStringWithTemplateName:(NSString *)templateName
{
    NSArray *taskInputsList = [self normalisedParameterNames:@{@"index":@(YES)}];

    NSMutableArray *taskInputs = nil;
    
    if ([taskInputsList count] > 0) {
        taskInputs = [self normalizeTemplateVariable:taskInputsList];
    }

    NSError *error = nil;
    
    // build template variables
    NSMutableDictionary *templateVariables = [NSMutableDictionary dictionaryWithCapacity:10];
    if (taskInputs) [templateVariables setObject:taskInputs forKey:@"task-inputs"];
    [self addDefaultTemplateVariables:templateVariables];
    
    NSString *nameString = [self processTemplateName:templateName object:templateVariables error:&error];
    if (error) {
        nameString = [self templateErrorString:error];
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
    switch (self.inputArgumentName) {
        
        case kMGSInputArgumentName:
        default:
            normalisedName = name;
            break;
            
        case kMGSInputArgumentNameAndType:
            normalisedName = [NSString stringWithFormat:@"%@ %@", name, typeName];
            break;
            
        case kMGSInputArgumentType:
            normalisedName = typeName;
            break;
            
        case kMGSInputArgumentTypeAndName:
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
    
    switch (self.inputArgumentCase) {
            
        case kMGSInputArgumentCamelCase:
            firstArgumentSelector = @selector(lowercaseString);
            argumentSelector = @selector(capitalizedString);
            break;
            
        case kMGSInputArgumentLowerCase:
            argumentSelector = @selector(lowercaseString);
            break;
            
        case kMGSInputArgumentInputCase:
        default:
            break;
            
        case kMGSInputArgumentPascalCase:
            argumentSelector = @selector(capitalizedString);
            break;
            
        case kMGSInputArgumentUpperCase:
            argumentSelector = @selector(uppercaseString);
            break;
    }
    
    // get lowercase name components
    NSMutableArray *nameComponents = [NSMutableArray arrayWithArray:[name componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];

    // get lowercase excluded components
    NSMutableArray *excludedNameComponents = [NSMutableArray arrayWithArray:[[self.inputArgumentNameExclusions lowercaseString] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    
    // remove excluded components
    for (NSString *exludedName in excludedNameComponents) {
        for (NSString *nameComponent in [nameComponents copy]) {
            if ([nameComponent compare:exludedName options:NSCaseInsensitiveSearch] == NSOrderedSame) {
                [nameComponents removeObject:nameComponent];
            }
        }
    }

    // set component case
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
    switch (self.inputArgumentStyle) {
           
        case kMGSInputArgumentUnderscoreSeparated:
            joinString = @"_";
            break;
            
        case kMGSInputArgumentWhitespaceRemoved:
        default:
            joinString = @"";
            break;
    }
    
    // reconstitute components with separator and apply prefix
    NSString *normalisedName = [nameComponents componentsJoinedByString:joinString];
    if (self.inputArgumentPrefix) {
        normalisedName = [self.inputArgumentPrefix stringByAppendingString:normalisedName];
    }
    
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
    self.inputArgumentName = _script.inputArgumentName;
    self.inputArgumentCase =  _script.inputArgumentCase;
    self.inputArgumentStyle =  _script.inputArgumentStyle;
    self.inputArgumentPrefix =  _script.inputArgumentPrefix;
    self.inputArgumentNameExclusions = _script.inputArgumentNameExclusions;
    
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
    
    // become the tag render delegate
    template.baseContext = [template.baseContext contextByAddingTagDelegate:self];
    
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

#pragma mark -
#pragma mark GRMustacheTagDelegate
/*
 
 - mustacheTag:willRenderObject:
 
 */
- (id)mustacheTag:(GRMustacheTag *)tag willRenderObject:(id)object
{
#pragma unused(tag)
    
    // render the tag
    switch (self.templateObjectRendering) {
            
        // use regex pattern rendering
        case MGSTemplateObjectRenderingRegexPattern:
            
            // if our object is going into a pattern string then escape it
            if ([object isKindOfClass:[NSString class]]) {
                object = [NSRegularExpression escapedPatternForString:object];
                MLogInfo(@"replaced key = %@", object);
            }
            break;
            
        // use default rendering
        default:
        case MGSTemplateObjectRenderingDefault:
            break;
    }
    return object;
}

@end
