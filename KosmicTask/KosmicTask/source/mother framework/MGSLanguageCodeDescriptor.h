//
//  MGSLanguageCodeDescriptor.h
//  KosmicTask
//
//  Created by Jonathan on 07/01/2013.
//
//

#import <Cocoa/Cocoa.h>
#import "MGSLanguage.h"
#import "GRMustache.h"  // a static library, not a framework

enum {
    MGSTemplateObjectRenderingDefault = 0,
    MGSTemplateObjectRenderingRegexPattern = 1,
};
typedef NSUInteger MGSTemplateObjectRendering;

@class MGSScript;
@class GRMustacheTemplateRepository;

@interface MGSLanguageCodeDescriptor : NSObject <GRMustacheTagDelegate> {
    MGSInputArgumentName _inputArgumentName;
    MGSInputArgumentCase _inputArgumentCase;
    MGSInputArgumentStyle _inputArgumentStyle;
    MGSCodeDescriptorCodeStyle _descriptorCodeStyle;
    MGSScript *_script;
    GRMustacheTemplateRepository *_templateRepository;
    NSString *_inputArgumentPrefix;
    NSString *_inputArgumentNameExclusions;
    MGSTemplateObjectRendering _templateObjectRendering;
    
#ifdef MGS_USE_MGTemplateEngine    
    id _templateEngine;
#endif
    MGSLanguage *_scriptLanguage;
}

@property MGSInputArgumentName inputArgumentName;
@property MGSInputArgumentCase inputArgumentCase;
@property MGSInputArgumentStyle inputArgumentStyle;
@property MGSCodeDescriptorCodeStyle descriptorCodeStyle;
@property (copy) NSString *inputArgumentPrefix;
@property (copy) NSString *inputArgumentNameExclusions;
@property (strong, nonatomic) MGSScript *script;

- (id)initWithScript:(MGSScript *)script;
- (NSString *)generateCodeString;
- (NSString *)generateTaskInputsCodeString;
- (NSString *)generateTaskBodyCodeString;
- (NSString *)generateTaskFunctionCodeString;
- (NSString *)generateTaskEntryCodeString;
- (NSArray *)normalisedParameterNames:(NSDictionary *)options;
- (NSString *)normalisedParameterNamesStringWithTemplateName:(NSString *)templateName;
- (NSString *)normalisedParameterName:(NSString *)name typeName:(NSString *)typeName;
- (NSString *)normalisedParameterName:(NSString *)name;
- (void)makeObjectsUnique:(NSMutableArray *)parameterNames;
//- (NSString *)processTemplate:(NSString *)inputTemplate object:(NSDictionary *)variables error:(NSError **)error;
- (NSString *)processTemplateName:(NSString *)templateName object:(NSDictionary *)variables error:(NSError **)error;
- (NSMutableDictionary *)generateTemplateVariables;
- (BOOL)templateNameExists:(NSString *)name;
- (NSString *)generateTaskEntryPatternString;
@end
