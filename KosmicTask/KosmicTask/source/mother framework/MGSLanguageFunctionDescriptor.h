//
//  MGSLanguageFunctionDescriptor.h
//  KosmicTask
//
//  Created by Jonathan on 07/01/2013.
//
//

#import <Cocoa/Cocoa.h>

@class MGSScript;
@class MGSLanguage;
@class GRMustacheTemplateRepository;

enum _MGSFunctionArgumentName {
    kMGSFunctionArgumentName = 0,
    kMGSFunctionArgumentNameAndType = 1,
    kMGSFunctionArgumentType = 2,
    kMGSFunctionArgumentTypeAndName = 3,
};
typedef NSUInteger MGSFunctionArgumentName;

enum _MGSFunctionArgumentCase {
    kMGSFunctionArgumentCamelCase= 0,
    kMGSFunctionArgumentLowerCase = 1,
    kMGSFunctionArgumentInputCase = 2,
    kMGSFunctionArgumentPascalCase = 3,
    kMGSFunctionArgumentUpperCase = 4,
};
typedef NSUInteger MGSFunctionArgumentCase;

enum _MGSFunctionArgumentStyle {
    kMGSFunctionArgumentHyphenated = 0,
    kMGSFunctionArgumentUnderscoreSeparated = 1,
    kMGSFunctionArgumentWhitespaceRemoved = 2,
};
typedef NSUInteger MGSFunctionArgumentStyle;

enum _MGSFunctionCodeStyle {
    kMGSFunctionCodeTaskInputs = 0,
    kMGSFunctionCodeTaskBody = 1,
    kMGSFunctionCodeTaskEntry = 2,
};
typedef NSUInteger MGSFunctionCodeStyle;

@interface MGSLanguageFunctionDescriptor : NSObject {
    MGSFunctionArgumentName _functionArgumentName;
    MGSFunctionArgumentCase _functionArgumentCase;
    MGSFunctionArgumentStyle _functionArgumentStyle;
    MGSFunctionCodeStyle _functionCodeStyle;
    MGSScript *_script;
    GRMustacheTemplateRepository *_templateRepository;
    
#ifdef MGS_USE_MGTemplateEngine    
    id _templateEngine;
#endif
    MGSLanguage *_scriptLanguage;
}

@property MGSFunctionArgumentName functionArgumentName;
@property MGSFunctionArgumentCase functionArgumentCase;
@property MGSFunctionArgumentStyle functionArgumentStyle;
@property MGSFunctionCodeStyle functionCodeStyle;
@property (assign) MGSScript *script;

- (void)copyFunctionArgumentsFromDescriptor:(MGSLanguageFunctionDescriptor *)descriptor;
- (NSString *)generateCodeString;
- (NSString *)generateTaskInputsCodeString;
- (NSString *)generateTaskBodyCodeString;
- (NSString *)generateTaskEntryCodeString;
- (NSArray *)normalisedParameterNames:(NSDictionary *)options;
- (NSString *)normalisedParameterNamesString;
- (NSString *)normalisedParameterName:(NSString *)name typeName:(NSString *)typeName;
- (NSString *)normalisedParameterName:(NSString *)name;
- (void)makeObjectsUnique:(NSMutableArray *)parameterNames;
- (NSString *)processTemplate:(NSString *)inputTemplate object:(NSDictionary *)variables error:(NSError **)error;
- (NSString *)processTemplateName:(NSString *)templateName object:(NSDictionary *)variables error:(NSError **)error;
- (NSMutableDictionary *)templateVariables;
@end
