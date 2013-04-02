//
//  MGSActionDetailEditViewController.m
//  Mother
//
//  Created by Jonathan on 03/03/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSActionDetailEditViewController.h"
#import "MGSTaskSpecifier.h"
#import "MGSNetClient.h"
#import "MGSClientScriptManager.h"
#import "MGSNotifications.h"
#import "MGSScript.h"
#import "MGSCapsuleTextCell.h"
#import "MGSNetRequest.h"
#import "MGSClientTaskController.h"
#import "MGSPreferences.h"
#import "MGSLanguagePluginController.h"

@implementation MGSActionDetailEditViewController
@synthesize action = _action;
@synthesize nameTextField = name;
@synthesize infoView;

// NSScrollView : documentView stuck in the bottom-left corner !
// http://www.cocoabuilder.com/archive/message/cocoa/2005/8/13/144214
//
//	
// note that the view was not scrolling properly
//
// from the docs.
// An NSClipView object determines whether to use flipped coordinates by looking at the coordinate system 
// of its document view. If the document view uses flipped coordinates, 
// so does the clip view. Using the same coordinate system ensures that the scroll 
// origin matches the bounds origin of the document view.
//
// note that it works okay for the parameter view - properly because NSSplitView uses flipped
// coordinates. making a flipped view the document of the scollview causes
// the clipview to flip - the controls are displayed top down!.
// so this is not the solution to keeping the view at the top of the scroll view.
// better perhaps to manually position the view after a resize.
//
// the solution to the problem of keeping the view in the top right
// corner is to make the document view flipped and fill that with another non flipped view!
//
// note that the view cannot seem to be made to auto fit the width of the scrollview.
// perhaps need to resize doc view manually.
//
//
// Also note that that we have subclassed NSViewController without loading the view from another nib
// but merely by setting the view outlet for the controller class.
// this gives access to the binding machinery including NSEditorRegistration
//
// I tried SubClassing NSController but without success.
// [self setRepresentedObject:[_action script]] seems ciritical to the operation of NSEditorRegistration
//
- (void)awakeFromNib
{
	// add flipped view as scrollview document
	[scrollView setDocumentView:actionDetailView];
	
	[created setLocale:[NSLocale currentLocale]];
	[modified setLocale:[NSLocale currentLocale]];
	
    if ([longDescription respondsToSelector:@selector(setUsesFindBar:)]) {
        [longDescription setUsesFindBar:YES];
    } else {
        [longDescription setUsesFindPanel:YES];
    }
    
	[(MGSCapsuleTextCell *)[definitionCapsule cell] setSizeCapsuleToFit:NO];
	[(MGSCapsuleTextCell *)[descriptionCapsule cell] setSizeCapsuleToFit:NO];
	[(MGSCapsuleTextCell *)[optionsCapsule cell] setSizeCapsuleToFit:NO];
	[(MGSCapsuleTextCell *)[infoCapsule cell] setSizeCapsuleToFit:NO];
}

/*
 
 set action
 
 */
- (void)setAction:(MGSTaskSpecifier *)anAction
{
	_action = anAction;
    
	MGSNetClient *netClient = [_action netClient];
	
	// bind group content values
	MGSClientScriptManager *scriptHandler = [netClient.taskController scriptManager];
	[group bind:@"contentValues" toObject:scriptHandler withKeyPath:@"groupNames" options:nil];

	// script type content values
	[scriptType bind:@"contentValues" toObject:self withKeyPath:@"representedObject.scriptTypes" options:nil];

	// bind controller to script
	MGSScript *script = [_action script];
	[self setRepresentedObject:script];
    
    // configure timeouts
    bool applyTimeout = [script applyTimeout];
    [script applyTimeoutDefaults];
    script.applyTimeout = applyTimeout; // we don't want to default this
    
    // if we bind directly to the model we loose the facilities provided by NSObjectController
    // such as automatic KVC validation
    _objectController = [[NSObjectController alloc] initWithContent:script];

    // binding options
    NSDictionary *bindingOptions1 = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithBool:YES], NSValidatesImmediatelyBindingOption, 
                                     [NSNumber numberWithBool:NO], NSAlwaysPresentsApplicationModalAlertsBindingOption, 
                                     nil];

	// set up bindings for main view
	[name bind:NSValueBinding toObject:_objectController withKeyPath:@"selection.name" options:bindingOptions1];
	[description bind:NSValueBinding toObject:_objectController withKeyPath:@"selection.description" options:nil];
	[longDescription bind:NSDataBinding toObject:self withKeyPath:@"representedObject.longDescription" options:nil];
	[group bind:NSValueBinding toObject:_objectController withKeyPath:@"selection.group" options:bindingOptions1];
	[scriptType bind:NSSelectedValueBinding toObject:self withKeyPath:@"representedObject.scriptType" options:nil];
	
	// set up bindings for bottom view
	
	// info - version
	[versionMajorText bind:NSValueBinding toObject:self withKeyPath:@"representedObject.versionMajor" options:nil];
	[versionMajorStepper bind:NSValueBinding toObject:self withKeyPath:@"representedObject.versionMajor" options:nil];
	[versionMinorText bind:NSValueBinding toObject:self withKeyPath:@"representedObject.versionMinor" options:nil];
	[versionMinorStepper bind:NSValueBinding toObject:self withKeyPath:@"representedObject.versionMinor" options:nil];
	[versionRevisionText bind:NSValueBinding toObject:self withKeyPath:@"representedObject.versionRevision" options:nil];
	[versionRevisionStepper bind:NSValueBinding toObject:self withKeyPath:@"representedObject.versionRevision" options:nil];
	[versionRevisionAuto bind:NSValueBinding toObject:self withKeyPath:@"representedObject.versionRevisionAuto" options:nil];

	// info - creation
	[author bind:NSValueBinding toObject:self withKeyPath:@"representedObject.author" options:nil];
	[authorNote bind:NSValueBinding toObject:self withKeyPath:@"representedObject.authorNote" options:nil];
	[published bind:NSValueBinding toObject:self withKeyPath:@"representedObject.published" options:nil];
	[created bind:NSValueBinding toObject:self withKeyPath:@"representedObject.created" options:nil];
	[modified bind:NSValueBinding toObject:self withKeyPath:@"representedObject.modified" options:nil];
	[modifiedAuto bind:NSValueBinding toObject:self withKeyPath:@"representedObject.modifiedAuto" options:nil];
	
	// options
	[useTimeoutButton bind:NSValueBinding toObject:self withKeyPath:@"representedObject.applyTimeout" options:nil];
	[timeout bind:NSValueBinding toObject:self withKeyPath:@"representedObject.timeout" options:nil];
	[timeout bind:NSEnabledBinding toObject:self withKeyPath:@"representedObject.applyTimeout" options:nil];

	[timeoutStepper bind:NSValueBinding toObject:self withKeyPath:@"representedObject.timeout" options:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], NSConditionallySetsEnabledBindingOption, nil]];
	[timeoutStepper bind:NSEnabledBinding toObject:self withKeyPath:@"representedObject.applyTimeout" options:nil];

	[timeoutUnitsPopUp bind:NSSelectedTagBinding toObject:self withKeyPath:@"representedObject.timeoutUnits" options:nil];
	[timeoutUnitsPopUp bind:NSEnabledBinding toObject:self withKeyPath:@"representedObject.applyTimeout" options:nil];
	
    // userInteractionMode popup
    [userInteractionMode bind:NSSelectedTagBinding toObject:self withKeyPath:@"representedObject.userInteractionMode" options:nil];
	 
}

/*
 
 toggle font panel
 
 */
- (IBAction)toggleFontPanel:(id)sender
{
	#pragma unused(sender)
	
	NSFontPanel *fontPanel = [NSFontPanel sharedFontPanel];
	
	if (![fontPanel isVisible]) {
		[fontPanel makeKeyAndOrderFront: self];
	} else {
		[fontPanel orderOut:self];
	}
}
/*
 
 toggle color panel
 
 */
- (IBAction)toggleColorPanel:(id)sender
{
	#pragma unused(sender)
	
	NSColorPanel *colorPanel = [NSColorPanel sharedColorPanel];
	
	if (![colorPanel isVisible]) {
		[colorPanel makeKeyAndOrderFront: self];
	} else {
		[colorPanel orderOut:self];
	}
}

/*
 
 refresh created date
 
 */
- (IBAction)refreshCreatedDate:(id)sender
{
	#pragma unused(sender)
	
	// update script
	[[_action script] setValue:[NSDate date] forKeyPath:@"created"];
}
/*
 
 refresh modified date
 
 */
- (IBAction)refreshModifiedDate:(id)sender
{
	#pragma unused(sender)
	
	// update script
	[[_action script] setValue:[NSDate date] forKeyPath:@"modified"];
}

/*
 
 -defaultScriptType:
 
 */
- (IBAction)defaultScriptType:(id)sender
{
	#pragma unused(sender)
	
	NSString *sType = [[_action script] scriptType];
	
	[[MGSLanguagePluginController sharedController] setDefaultScriptType:sType];
}
@end
