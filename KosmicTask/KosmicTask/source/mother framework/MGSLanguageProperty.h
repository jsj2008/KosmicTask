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
	id value;
	id initialValue;
	NSDictionary *optionValues;
	id defaultOptionKey;
	MGSLanguagePropertyType propertyType;
	MGSLanguageRequestType requestType;
	BOOL editable;
	NSString *infoText;
	BOOL canReset;
	BOOL allowReset;
	BOOL hasInitialValue;
	BOOL isList;
	id delegate;
}

@property (readonly) MGSLanguagePropertyType propertyType;
@property (copy, readonly) NSString *key;
@property (copy) NSString *name;
@property (assign) id value;
@property (assign) id initialValue;
@property (copy) NSDictionary *optionValues;
@property MGSLanguageRequestType requestType;
@property BOOL editable;
@property (readonly) BOOL canReset;
@property BOOL allowReset;
@property (readonly) BOOL hasInitialValue;
@property (copy) NSString *infoText;
@property (readonly) BOOL isList;
@property (assign) id defaultOptionKey;
@property (assign) id delegate;

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
