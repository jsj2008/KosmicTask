//
//  MGSResult.h
//  Mother
//
//  Created by Jonathan on 08/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSMotherModes.h"
#import "MGSDisposableObject.h"

@class MGSTaskSpecifier;
@class MGSNetAttachments;

@interface MGSResult : MGSDisposableObject {
	id __unsafe_unretained _object;										// the result object
	MGSTaskSpecifier *_action;					// action associated with the result
	NSAttributedString *_resultScriptString;		// result object string as returned by the script component
	NSAttributedString *_resultLogString;           // log string
    MGSNetAttachments *__weak _attachments;				// attachments
	NSMutableArray *_progressArray;					// progress array 
	eMGSMotherResultView _viewMode;					// view mode
	NSMutableAttributedString *_resultString;		// make this weak so that it becomes deallocated when no longer reqd
	NSArray * __weak _resultTree;					// make weak
}

@property (unsafe_unretained) id object;
@property (strong) MGSTaskSpecifier *action;
@property (copy) NSAttributedString *resultScriptString;
@property (copy) NSAttributedString *resultLogString;
@property (weak) MGSNetAttachments *attachments;
@property (copy) NSMutableArray *progressArray;
@property eMGSMotherResultView viewMode;

+ (NSDictionary *)defaultAttributes;
- (NSMutableAttributedString *)resultString;
- (NSString *)shortResultString;
- (NSArray *)resultTreeArray;
@end
