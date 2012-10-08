//
//  MGSTaskSearchViewController.h
//  Mother
//
//  Created by Jonathan on 01/12/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSClientNetRequest.h"
#import "MGSViewDelegateProtocol.h"

@class MGSTaskSpecifierManager;
@class MGSScopeBarViewController;
@class MGSTaskSpecifier;

@interface MGSTaskSearchViewController : NSViewController <MGSNetRequestOwner, MGSViewDelegateProtocol> {
	id _delegate;
	NSUInteger _searchID;
	MGSTaskSpecifierManager *_taskSpecManager;
	NSArray *_resultActionArray;
	IBOutlet NSTableView *_searchTableView;
	NSString *_queryString;
	IBOutlet NSTextField *_foundTextField;
	IBOutlet NSProgressIndicator *_searchProgressIndicator;
	BOOL _searchInProgress;
	NSInteger _searchTargetsQueried;
	NSInteger _searchTargetsResponded;
	NSString *_searchActivity;
	NSInteger _numberOfItemsFound;
	NSUInteger _numberOfMatches;
	IBOutlet MGSScopeBarViewController *_scopeBarViewController;
	MGSTaskSpecifier *_delegatedAction;
}

@property id delegate;
@property (assign) NSArray *resultActionArray;
@property BOOL searchInProgress;
@property (copy) NSString *searchActivity;
@property NSInteger searchTargetsQueried;
@property NSInteger searchTargetsResponded;
@property NSInteger numberOfItemsFound;
@property NSUInteger numberOfMatches;

- (void)sendSearchQueryToSharedClients:(NSDictionary *)searchDict;
- (void)clearSearchResults;
- (void)search:(NSString *)queryString;
- (void)sendSearchQuery:(NSDictionary *)searchDict toClientServiceName:(NSString *)serviceName;
- (void)openTaskInNewWindow:(id)sender;
- (void)openTaskInNewTab:(id)sender;

@end

@protocol MGSTaskSearchViewController
- (void)searchViewController:(MGSTaskSearchViewController *)sender searchFilterChanged:(NSNotification *)note;
- (void)taskSearchView:(MGSTaskSearchViewController *)sender actionSelected:(MGSTaskSpecifier *)action;
@end
