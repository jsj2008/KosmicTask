//
//  MGSScopeBarViewController.h
//  Mother
//
//  Created by Jonathan on 28/11/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGScopeBarDelegateProtocol.h"

// search target
#define MGSSearchThisMac 0
#define MGSSearchShared 1
#define MGSSearchOtherMac 2

// search attributes
#define MGSSearchContent 0
#define MGSSearchScript 1

@class MGSScopeBarViewController;
@class MGSNetClient;

@protocol MGSScopeBarViewControllerDelegate
- (void)scopeBarControllerChanged:(MGSScopeBarViewController *)scopeBarController ;
@end

@interface MGSScopeBarViewController : NSViewController <MGScopeBarDelegate> {
	IBOutlet NSTextField *labelField;
	IBOutlet MGScopeBar *scopeBar;
	IBOutlet NSView *accessoryView;
	NSMutableArray *groups;
	IBOutlet id _delegate;
	NSInteger _searchTarget;
	NSInteger _searchAttribute;
	NSString *_searchTargetIdentifier;
}

- (void)setNetClient:(MGSNetClient * )netClient;

@property id delegate;

@property (retain) NSMutableArray *groups;
@property (readonly) NSInteger searchTarget;
@property (readonly) NSInteger searchAttribute;
@property (readonly) NSString *searchTargetIdentifier;

@end
