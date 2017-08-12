//
//  MGSLAddWindowController.h
//  Mother
//
//  Created by Jonathan on 02/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MGSLAddWindowController : NSWindowController {
	IBOutlet NSTableView *_detailTableView;
	IBOutlet NSPopUpButton *_licenceTypePopup;
	NSString *__weak _path;
	NSDictionaryController *_licenceDictionaryController;
	NSInteger _licenceType;
	
	IBOutlet NSMenu *adminLicenceTypeMenu;
	IBOutlet NSMenu *userLicenceTypeMenu;
}

@property (weak, readonly) NSString *path;
@property NSInteger licenceType;


- (id)initWithPath:(NSString *)path;
- (IBAction)addLicence:(id)sender;
- (IBAction)cancel:(id)sender;
- (NSDictionary *)optionDictionary;

@end
