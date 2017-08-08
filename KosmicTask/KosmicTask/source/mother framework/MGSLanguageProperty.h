//
//  MGSLanguageProperty.h
//  KosmicTask
//
//  Created by Jonathan on 30/08/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MGSLanguageProperty;
@class MGSLanguagePropertyManager;


enum _MGSLanguagePropertyType{
	kMGSLanguagePropertyTypeAll = -1,
	kMGSLanguageProperty,		// immutable
	kMGSLanguageEditableOption,	// mutable
};
typedef NSInteger MGSLanguagePropertyType;

enum {
	kMGSLanguageRequest = -1,
	kMGSBuildRequest,
	kMGSExecuteRequest,
	kMGSInterfaceRequest,
	kMGSRunRequest,
	kMGSCocoaRequest,
	kMGSResultRepresentationRequest,
    kMGSTaskInputRequest,
};
typedef NSInteger MGSLanguageRequestType;

@interface MGSLanguageProperty : NSObject <NSCopying> {
	NSString *key;
	NSString *name;
	id __strong value;
	id __strong initialValue;
	NSDictionary *optionValues;
	id __strong defaultOptionKey;
	MGSLanguagePropertyType propertyType;
	MGSLanguageRequestType requestType;
	BOOL editable;
	NSString *infoText;
	BOOL canReset;
	BOOL allowReset;
	BOOL hasInitialValue;
	BOOL isList;
	id __weak delegate;
}

@property (readonly) MGSLanguagePropertyType propertyType;
@property (copy, readonly) NSString *key;
@property (copy) NSString *name;
@property (strong) id value;
@property (strong) id initialValue;
@property (copy) NSDictionary *optionValues;
@property MGSLanguageRequestType requestType;
@property BOOL editable;
@property (readonly) BOOL canReset;
@property BOOL allowReset;
@property (readonly) BOOL hasInitialValue;
@property (copy) NSString *infoText;
@property (readonly) BOOL isList;
@property (strong) id defaultOptionKey;
@property (weak) id delegate;

+ (NSString *)missingProperty;
+ (BOOL)isMissingProperty:(NSString *)property;
- (id)initWithKey:(NSString*)aKey name:(NSString *)aName value:(id)aValue;
- (IBAction)resetToInitialValue:(id)sender;
- (id)keyForOptionValue;
- (void)updateValue:(id)newValue;
- (void)updateOptionKey:(id)newKey;
- (NSArray *)sortedOptionKeys;
- (void)log;

@end
