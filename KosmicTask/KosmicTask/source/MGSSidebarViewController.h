//
//  MGSSidebarViewController.h
//  Mother
//
//  Created by Jonathan on 14/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MGSOutlineViewNode;
@class MGSNetClient;
@class MGSSidebarOutlineView;

@interface MGSSidebarViewController : NSViewController {
	IBOutlet MGSSidebarOutlineView *outlineView;
	NSTreeController *clientTreeController;
	MGSOutlineViewNode *_homeNode;
	MGSOutlineViewNode *_sharedNode;
	MGSNetClient *selectedNetClient;
	id selectedObject;
	MGSOutlineViewNode *selectedObjectNode;
	
	NSArray *_selectionIndexPaths;
	NSTreeNode *_selectionGroupNode;
	
	NSMutableArray *_netClients;
	NSMutableArray *clientTree;
	BOOL _postNetClientSelectionNotifications;
	NSTimer *cellAnimationTimer;
    NSMutableArray *_netClientsAnimated;
	//NSMapTable *outlineNodeMapTable;
	NSMutableDictionary *outlineNodeCache;
}

@property (assign) NSMutableArray *clientTree;
@property (readonly) MGSNetClient *selectedNetClient;
@property (readonly) id selectedObject;
@property (readonly) MGSOutlineViewNode *selectedObjectNode;

- (IBAction)openTaskInNewTab:(id)sender;
- (IBAction)openTaskInNewWindow:(id)sender;

@end
