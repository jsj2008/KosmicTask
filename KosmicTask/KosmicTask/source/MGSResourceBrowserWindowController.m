//
//  MGSLanguageResourcesWindowController.m
//  KosmicTask
//
//  Created by Jonathan on 12/06/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSResourceBrowserWindowController.h"
#import "MGSPreferences.h"
#import "MGSScriptParameter+Application.h"

static id mgs_sharedController = nil;

const char MGSContextDocumentEdited;

// class extension
@interface MGSResourceBrowserWindowController()
@end

@implementation MGSResourceBrowserWindowController


/*
 
 shared controller singleton
 
 */
+ (id)sharedController 
{
	@synchronized(self) {
		if (nil == mgs_sharedController) {
			(void)[[self alloc] init];  // assignment occurs below
			
			// load the nib
			[mgs_sharedController window];
		}
	}
	return mgs_sharedController;
}

/*
 
 alloc with zone for singleton
 
 */
+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self) {
        if (mgs_sharedController == nil) {
            mgs_sharedController = [super allocWithZone:zone];
            return mgs_sharedController;  // assignment and return on first allocation
        }
    }
    return nil; //on subsequent allocation attempts return nil
} 

/*
 
 copy with zone for singleton
 
 */
- (id)copyWithZone:(NSZone *)zone
{
#pragma unused(zone)
    return self;
}


/*
 
 - init
 
 */
- (id)init
{
	self = [super init];
	if (self) {
		self = [super initWithWindowNibName:@"ResourceBrowserWindow"];
	}
	
	return self;
}

/*
 
 - awakeFromNib
 
 */
- (void)awakeFromNib
{
	if (nibLoaded) {
		return;
	}
	
	nibLoaded = YES;

    // define a script to be used to demonstrate template tendering.
    NSString *inputName = NSLocalizedString(@"task input", @"comment");
    MGSScript *script = [MGSScript new];
    
    // define some default parameters
    for (NSUInteger i = 0; i < 2; i++) {
        MGSScriptParameter *parameter = [MGSScriptParameter newWithDefaultTypeName];
        parameter.name = inputName;
        [script.parameterHandler insertItem:parameter atIndex:i];
    }
    

	// load the resource browser view
	resourceBrowserViewController = [[MGSResourceBrowserViewController alloc] init];
	[resourceBrowserViewController view];
	[[resourceBrowserViewController view] setFrame:[[self.window contentView] frame]];
	resourceBrowserViewController.editable = YES;
    resourceBrowserViewController.script = script;
	[resourceBrowserViewController buildResourceTree];	
    
	// insert into content
	[self.window setContentView:[resourceBrowserViewController view]];
	
	// KVO
	[resourceBrowserViewController addObserver:self forKeyPath:@"documentEdited" options:0 context:(void *)&MGSContextDocumentEdited];

	// restore view frames
	NSDictionary *viewDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
			MGSWindowResourceBrowserOutlineSplitViewFrames, @"MainSplitView",
			MGSWindowResourceBrowserTableSplitViewFrames, @"ResourceSplitView", nil];
	[resourceBrowserViewController setViewFrameDefaults:viewDefaults];
}

#pragma mark -
#pragma mark Accessors



#pragma mark -
#pragma mark KVO

/*
 
 - observeValueForKeyPath:ofObject:change:context:
 
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
#pragma unused(keyPath)
#pragma unused(object)
#pragma unused(change)
	
	if (context == (void *)&MGSContextDocumentEdited) {
		[[self window] setDocumentEdited:resourceBrowserViewController.documentEdited];
	}
}

#pragma mark -
#pragma mark Window

/*
 
 - showWindow:
 
 */
- (void)showWindow:(id)sender
{
#pragma unused(sender)
		
	[super showWindow:sender];
}

#pragma mark -
#pragma mark Notifications

/*
 
 - windowWillClose:
 
 */
- (void)windowWillClose:(NSNotification *)notification
{
#pragma unused(notification)
		
	[resourceBrowserViewController saveDocument:self];
}

/*
 
 - windowDidResignKey:
 
 */
- (void)windowDidResignKey:(NSNotification *)notification
{
#pragma unused(notification)
    
	[resourceBrowserViewController saveDocument:self];
}

#pragma mark -
#pragma mark URL handling

/*
 
 - resolveURL:
 
 */
- (BOOL)resolveURL:(NSString *)url
{
#pragma unused(url)

	[self showWindow:self];
	
	//NSLog(@"Custom URL = %@", url);
	
	/*
	 urls should be of the form
	 
	 KosmicTaskResource://languages/ruby/application/documents/<ID>
	
	 using the doucment ID for the final part of the path means that document titles can be changed
	 with breaking the link
	 
	 */
	
	return YES;
}

@end
