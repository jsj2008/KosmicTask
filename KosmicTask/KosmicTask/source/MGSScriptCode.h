//
//  MGSScriptCode.h
//  Mother
//
//  Created by Jonathan on 11/03/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSDictionary.h"

enum _MGSScriptCodeRepresentation {
	MGSScriptCodeRepresentationUndefined = 0,		// undefined representation
	MGSScriptCodeRepresentationStandard = 1,		// standard representation
	MGSScriptCodeRepresentationBuild = 2,			// build representation 
	MGSScriptCodeRepresentationSave = 3,
};
typedef NSInteger MGSScriptCodeRepresentation;

@interface MGSScriptCode : MGSDictionary {
    NSAttributedString *_attributedSourceFromBuild;
}

@property (assign) NSAttributedString *attributedSourceFromBuild;

- (void)setDict:(NSMutableDictionary *)dict;
- (void)setRepresentation:(MGSScriptCodeRepresentation)value;
- (BOOL)conformToRepresentation:(MGSScriptCodeRepresentation)representation;

// source as RTF data stream - used to store compiled source
- (NSData *)rtfSource;
- (void)setRtfSource:(NSData *)data;

// attributed source
- (NSAttributedString *)attributedSource;
- (void)setAttributedSource:(NSAttributedString *)theSource;

// source 
- (NSString *)source;
- (void)setSource:(NSString *)theSource;
- (NSData *)sourceData;

// compiled source data
- (NSData *)compiledData;
- (void)setCompiledData:(NSData *)data withFormat:(NSString *)format;
- (NSString *)compiledDataFormat;

- (BOOL)conformToRepresentation:(MGSScriptCodeRepresentation)representation options:(NSDictionary *)options;
@end
