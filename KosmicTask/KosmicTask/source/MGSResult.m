//
//  MGSResult.m
//  Mother
//
//  Created by Jonathan on 08/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSResult.h"
#import "MGSResultFormat.h"
#import "MGSTaskSpecifier.h"
#import "MGSImageManager.h"
#import "MGSError.h"
#import "MGSScript.h"
#import "MGSKeyImageAndText.h"
#import "MGSNetAttachments.h"
#import "NSString_Mugginsoft.h"
#import "MLog.h"
#import "NSArray_Tree_Mugginsoft.h"
#import "NSObject_Mugginsoft.h"
#import "MGSObjectStyler.h"
#import "MGSPreferences.h"

// class extension
@interface MGSResult ()
@end

@interface MGSResult (Representations)
- (void)buildObjectRepresentations;
- (void)buildTreeRepresentation;
- (void)buildStringRepresentation;
@end

@interface MGSResult (Private)
@end

@implementation MGSResult

@synthesize object = _object;
@synthesize action = _action;
@synthesize resultScriptString = _resultScriptString;
@synthesize resultLogString = _resultLogString;
@synthesize attachments = _attachments;
@synthesize progressArray = _progressArray;
@synthesize viewMode = _viewMode;

/*
 
 + defaultAttributes
 
 */
+ (NSDictionary *)defaultAttributes
{
	// get font
	NSString *fontName = [[NSUserDefaults standardUserDefaults] stringForKey:MGSResultViewFontName];
	CGFloat fontSize = [[NSUserDefaults standardUserDefaults] floatForKey:MGSResultViewFontSize];
	NSFont *defaultFont = [NSFont fontWithName:fontName size:fontSize];
	
	// get color
	NSData *defaultColorData = [[NSUserDefaults standardUserDefaults] dataForKey:MGSResultViewColor];
	NSColor *defaultColor = [NSUnarchiver unarchiveObjectWithData:defaultColorData];
	
	// default attributes
	NSDictionary *defaultAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
									   defaultFont, NSFontAttributeName,
									   defaultColor, NSForegroundColorAttributeName,
									   nil];
	
	return defaultAttributes;
	
}


/*
 
 init 
 
 */
- (id)init
{
	if ([super init]) {
		self.viewMode = kMGSMotherResultViewDocument;
	}
	return self;
}
/*

 description

  NSPopupButton bindings uses this for display name if ContentValues not bound
 
 */
- (NSString *)description
{
	return [_action name];
}

/*
 
 set result object
 
 */
- (void)setObject:(id)anObject
{
	// store our result object here.
	// if object is large and produces large tree or
	// a large resultString then the allocations required for this object can be large.
	_object = anObject;
}

/*
 
 result object
 
 */
-(id)object
{
	return _object;
}

/*
 
 result string
 
 form dynamically to keep memory usage low
 
 */
- (NSMutableAttributedString *)resultString
{
	@try {
		// _resultString is declared __weak
		// so that when it becomes unreachable it will be set to nil.
		// this will reduce memory usage.
		//
		// this approach works very well. the object stays allocated as along as it is needed
		// after which is deallocated. When needed again we just recreate it.
		//
		if (!_resultString) {
			//
			// form a string representation of our object
			//
			id result = nil;
			
			//
			// get a representation of our result.
			//
			// mgs_attributedDescriptionWithStyle: is defined within an NSObject category so should
			// always be available.
			//
			// descriptionWithDepthString: is defined within an NSObject category so should
			// always be available.
			// it indents the description string using n x @"\t" prefix to represent the
			// object hierarchy.
			//
			
			if ([self.object respondsToSelector:@selector(mgs_attributedDescriptionWithStyle:)]) {
				
						 
				NSDictionary *attributes = [[self class] defaultAttributes];
				
				// get styled description
				result = [self.object mgs_attributedDescriptionWithStyle:[MGSObjectStyler styleDictionaryWithAttributes:attributes]];
				
			} else if ([self.object respondsToSelector:@selector(descriptionWithDepthString:)]) {
				
				result = [self.object descriptionWithDepthString:@"\t"];
				
			} else if ([self.object respondsToSelector:@selector(description)]) {
				
				result = [self.object description];
				
			} else if ([self.object respondsToSelector:@selector(stringValue)]) {
				
				result = [self.object stringValue];
			}
			
			
			// supply default result string
			if (!result) {
				result = NSLocalizedString(@"(empty result)", @"Empty task result found");
			}
			
			// convert NSString to attributed string if necessary
			if ([result isKindOfClass:[NSString class]]) {
				result = [[NSAttributedString alloc] initWithString:result];
			}
			
			// sanity check the class
			if (![result isKindOfClass:[NSAttributedString class]]) {
				result =[[NSAttributedString alloc] initWithString: NSLocalizedString(@"(cannot build result representation)", @"Error building result representation")];
			}
			
			// assemble final result
			NSMutableAttributedString *mutableResult = [[NSMutableAttributedString alloc] initWithString:@"\n"];
			[mutableResult appendAttributedString:result];
			
			_resultString = mutableResult;
		}
	} @catch(NSException *e) {
		_resultString =[[NSMutableAttributedString alloc] initWithString: NSLocalizedString(@"(exception building result representation)", @"Exception building result representation")];
	}
	return _resultString;
}

/*
 
 result tree array
 
 form dynamically to keep memory usage low
 
 */
- (NSArray *)resultTreeArray
{
	// result tree declared __weak
	if (!_resultTree) {
		_resultTree = [NSArray arrayTreeWithObject:self.object];
	}
	
	return _resultTree;
}


/*
 
 short result string
 
 */
- (NSString *)shortResultString
{
	NSUInteger maxLength = 100;
	NSString *stringValue = [[self resultString] string];
	
	// we need to limit the length of text in our cell
	if ([stringValue length] > maxLength) {
		stringValue = [stringValue substringToIndex:maxLength];
		stringValue = [NSString stringWithFormat:@"%@ ...", stringValue];
	}
	
	// remove CRLF otherwise text may wrap
	return [stringValue mgs_stringWithOccurrencesOfCrLfRemoved];
}

#pragma mark -
#pragma mark attachments

/*
 
 - setAttachements:
 
 */
- (void)setAttachments:(MGSNetAttachments *)theAttachments
{
    _attachments = theAttachments;
    [_attachments retainDisposable];
}

#pragma mark -
#pragma mark memory management
/*
 
 finalize
 
 */
- (void)finalize
{
    if (!_disposed) {
        MLogInfo(@"%@-finalize receieved without prior -dispose.", self);
    }
#ifdef MGS_LOG_FINALIZE 
	MLog(DEBUGLOG, @"finalized");
#endif
    
	[super finalize];
}

#pragma mark -
#pragma mark resource management
/*
 
 - dispose
 
 */
- (void)dispose
{
    if (_disposed) {
        return;
    }
    _disposed = YES;
    [_attachments releaseDisposable];
}

@end

#pragma mark private category
@implementation MGSResult (Private)
@end

