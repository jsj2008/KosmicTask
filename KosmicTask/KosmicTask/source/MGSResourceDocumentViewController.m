//
//  MGSResourceDocumentViewController.m
//  KosmicTask
//
//  Created by Jonathan on 10/07/2011.
//  Copyright 2011 mugginsoft.com. All rights reserved.
//

#import "MGSResourceItem.h"
#import "MGSResourceDocumentViewController.h"

const char MGSContextResourceDocFileType;

@interface MGSResourceDocumentViewController()
- (void)selectTabViewItem;
- (void)loadHTMLDoc;
@end

@implementation MGSResourceDocumentViewController

@synthesize mode, editModeActive, selectedResource, documentEdited;

/*
 
 - initWithNibName:bundle:
 
 */
- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	if (self) {
		mode = kMGSResourceDocumentModeView;
		editModeActive = NO;
		documentEdited = NO;
	}
	
	[self addObserver:self forKeyPath:@"selectedResource.docFileType" options:0 context:(void *)&MGSContextResourceDocFileType];
	
	return self;
}

/*
 
 - setMode:
 
 */
- (void)setMode:(MGSResourceDocumentMode)value
{
	BOOL editActive = NO;
	
	switch (value) {
		case kMGSResourceDocumentModeView:
			[self.selectedResource loadDerivedResources];
			[self loadHTMLDoc];
			break;
			
		case kMGSResourceDocumentModeEdit:
			editActive = YES;
			break;
			
		default:
			NSAssert(NO, @"Invalid option.");
	}	
	
	mode = value;
	self.editModeActive = editActive;
	[self selectTabViewItem];
}

/*
 
 - setSelectedResource:
 
 */
- (void)setSelectedResource:(MGSResourceItem *)item
{
	//self.documentEdited = NO;
	
	if (!item) return;
	
	selectedResource = item;
	
	switch (selectedResource.docFileType) {
		case MGSResourceItemRTFDFile:
			break;
			
		case MGSResourceItemMarkdownFile:
			[self loadHTMLDoc];
			break;
			
		default:
			NSAssert(NO, @"Bad document file type.");
			
	}
	
}


#pragma mark -
#pragma mark Actions
/*
 
 - docFormatAction:
 
 */
- (IBAction)docFormatAction:(id)sender
{
#pragma unused(sender)
	
	MGSResourceItemFileType fileType = [docType selectedTag];
	[self.selectedResource updateDocFileType:fileType];
	
	self.documentEdited = YES;
}

/*
 
 - docModeAction:
 
 */
- (IBAction)docModeAction:(id)sender
{
#pragma unused(sender)
	
	switch (self.mode) {
		case kMGSResourceDocumentModeView:
			[self.selectedResource loadDerivedResources];
			[self loadHTMLDoc];
			break;
			
		case kMGSResourceDocumentModeEdit:
			break;
			
		default:
			NSAssert(NO, @"Invalid option.");
	}		

}

#pragma mark -
#pragma mark Observing and notifications
/*
 
 observe value for key path
 
 */
- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
	if (context == (void *)&MGSContextResourceDocFileType) {
		[self selectTabViewItem];
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}	

/*
 
 - selectTabViewItem
 
 */
- (void)selectTabViewItem
{
	if (!selectedResource) return;
	
	NSString *tabIdentifier = nil;
	
	switch (selectedResource.docFileType) {
		case MGSResourceItemRTFDFile:
			tabIdentifier = @"rtf";	// edit and view
			break;
			
		case MGSResourceItemMarkdownFile:
			if (self.editModeActive) {
				tabIdentifier = @"text";	// edit
			} else {
				tabIdentifier = @"html";	// view
			}
			break;
			
		default:
			NSAssert(NO, @"Bad document file type.");
			
	}
	
	[documentTabView selectTabViewItemWithIdentifier:tabIdentifier];
}

/*
 
 - loadHTMLDoc 
 
 */
- (void)loadHTMLDoc
{
	NSString *html = self.selectedResource.htmlResource;
	if (!html) html = @"";
	
	[[webView mainFrame] loadHTMLString:html baseURL:nil];
}

#pragma mark -
#pragma mark NSTextView delegate
/*
 
 - textDidChange:
 
 */
- (void)textDidChange:(NSNotification *)notification
{
#pragma unused(notification)
	
	self.documentEdited = YES;
}

/*
 
 - controlTextDidChange:
 
 */
- (void)controlTextDidChange:(NSNotification *)notification
{
#pragma unused(notification)
	
	self.documentEdited = YES;
}

@end
