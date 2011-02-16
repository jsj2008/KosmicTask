//
//  MGSLWindowController.h
//  Mother
//
//  Created by Jonathan on 30/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MGSLAddWindowController;
@class MGSLM;

@interface MGSLWindowController : NSWindowController <NSOpenSavePanelDelegate> {
	IBOutlet NSTableView *_licencesTableView;
	IBOutlet NSTableView *_detailTableView;
	IBOutlet NSButton *_removeLicenceButton;
	
	MGSLM *_licencesController;
	NSDictionaryController *_licenceDictionaryController;
	id _selectedItem;
	BOOL _allowRemoveLicence;
	
	MGSLAddWindowController *_addController;
}

@property id selectedItem;
@property BOOL allowRemoveLicence;

+ (MGSLWindowController *)sharedController;


- (IBAction)buyLicences:(id)sender;
- (IBAction)addLicence:(id)sender;
- (IBAction)removeLicence:(id)sender;
- (void)confirmAdd:(NSString *)path;
- (void)updateSelectedItem:(NSArrayController *)object;
@end
