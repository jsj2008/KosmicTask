//
//  MGSLanguageCodeDescriptor.h
//  KosmicTask
//
//  Created by Jonathan on 07/01/2013.
//
//

#import <Cocoa/Cocoa.h>
#import "MGSLanguage.h"

@class MGSScript;

@class GRMustacheTemplateRepository;


@interface MGSLanguageCodeDescriptor : NSObject {
    MGSFunctionArgumentName _functionArgumentName;
    MGSFunctionArgumentCase _functionArgumentCase;
    MGSFunctionArgumentStyle _functionArgumentStyle;
    MGSCodeDescriptorCodeStyle _descriptorCodeStyle;
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
@property MGSCodeDescriptorCodeStyle descriptorCodeStyle;
@property (assign) MGSScript *script;

- (id)initWithScript:(MGSScript *)script;
- (void)copyFunctionArgumentsFromDescriptor:(MGSLanguageCodeDescriptor *)descriptor;
- (NSString *)generateCodeString;
- (NSString *)generateTaskInputsCodeString;
- (NSString *)generateTaskBodyCodeString;
- (NSString *)generateTaskFunctionCodeString;
- (NSString *)generateTaskEntryCodeString;
- (NSArray *)normalisedParameterNames:(NSDictionary *)options;
- (NSString *)normalisedParameterNamesString;
- (NSString *)normalisedParameterName:(NSString *)name typeName:(NSString *)typeName;
- (NSString *)normalisedParameterName:(NSString *)name;
- (void)makeObjectsUnique:(NSMutableArray *)parameterNames;
//- (NSString *)processTemplate:(NSString *)inputTemplate object:(NSDictionary *)variables error:(NSError **)error;
- (NSString *)processTemplateName:(NSString *)templateName object:(NSDictionary *)variables error:(NSError **)error;
- (NSMutableDictionary *)templateVariables;
- (BOOL)templateNameExists:(NSString *)name;
@end
