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
	id __unsafe_unretained _delegate;
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

@property (unsafe_unretained) id delegate;
@property (strong) NSArray *resultActionArray;
@property (nonatomic) BOOL searchInProgress;
@property (copy) NSString *searchActivity;
@property (nonatomic) NSInteger searchTargetsQueried;
@property (nonatomic) NSInteger searchTargetsResponded;
@property (nonatomic) NSInteger numberOfItemsFound;
@property NSUInteger numberOfMatches;

- (void)sendSearchQueryToAllClients:(NSDictionary *)searchDict;
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
