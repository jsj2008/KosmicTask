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
	MGSNetClient *__weak selectedNetClient;
	id __unsafe_unretained selectedObject;
	MGSOutlineViewNode *__weak selectedObjectNode;
	
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

@property (strong) NSMutableArray *clientTree;
@property (weak, readonly) MGSNetClient *selectedNetClient;
@property (unsafe_unretained, readonly) id selectedObject;
@property (weak, readonly, nonatomic) MGSOutlineViewNode *selectedObjectNode;

- (IBAction)openTaskInNewTab:(id)sender;
- (IBAction)openTaskInNewWindow:(id)sender;

@end
