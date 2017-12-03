//
//  MGSTaskSpecifierManager.h
//  Mother
//
//  Created by Jonathan on 18/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MGSTaskSpecifierManager;
@class MGSNetClient;
@class MGSTaskSpecifier;
@class MGSResult;
@class MGSScript;

@protocol MGSTaskSpecifierManager
@optional
- (void)actionSpecifierAdded:(id)action;
- (void)actionSpecifierWillBeAdded;
@end


// let NSObjectController take the strain
@interface MGSTaskSpecifierManager : NSArrayController {
	MGSTaskSpecifierManager *_history;	// action history
	BOOL _keepHistory;	// keep a history for this object
	BOOL _isHistory;	// this object is a history
	NSUInteger _maxHistoryCount;
	id __unsafe_unretained _delegate;
}

@property (nonatomic) BOOL keepHistory;

+ (id)sharedController;
- (id) initAsHistory;
- (BOOL)saveToPath:(NSString *)path;
- (BOOL)loadFromPath:(NSString *)path;
- (NSString *)historyPath;
- (void)addCompletedActionCopy:(MGSTaskSpecifier *)anAction withResult:(MGSResult *)result;
- (void)removeAllObjects;
- (id)newTaskSpecForNetClient:(MGSNetClient *)netClient script:(MGSScript *)script;

@property (readonly) MGSTaskSpecifierManager *history;
@property (unsafe_unretained) id delegate;
@end
