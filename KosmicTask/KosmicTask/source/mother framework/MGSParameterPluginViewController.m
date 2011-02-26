//
//  MGSParameterSubViewController.m
//  Mother
//
//  Created by Jonathan on 18/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSParameterPluginViewController.h"
#import "MGSNotifications.h"

// class extension
@interface MGSParameterPluginViewController()
- (void)updateModel:(NSNotification *)notification;
- (void)viewFrameDidChange:(NSNotification *)note;
@end

@implementation MGSParameterPluginViewController

@synthesize canDragHeight = _canDragHeight;
@synthesize canDragMiddleView = _canDragMiddleView;
@synthesize modelDataModified = _modelDataModified;
@synthesize plugin = _plugin;
@synthesize parameterValue = _parameterValue;
@synthesize updatesDocumentEdited = _updatesDocumentEdited;
@synthesize sendAsAttachment = _sendAsAttachment;
@synthesize valid = _valid;
@synthesize validationString = _validationString;
@synthesize defaultValueSelected = _defaultValueSelected;
@synthesize delegate;

/*
 
 init with nib name and bundle
 
 designated initialiser
 
 */
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if ([super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
			
		_plist = [[NSMutableDictionary alloc] init];
		_modelDataModified = NO;
		_updatesDocumentEdited = NO;
		_sendAsAttachment = NO;
		_valid = YES;
		_defaultValueSelected = YES;
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateModel:) name:MGSNoteEditWindowUpdateModel object:nil];
		
		/*
		 
		 we may need more control over when view notifications are sent
		 */
		if (NO) {
			[self.view setPostsFrameChangedNotifications:YES];
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewFrameDidChange:) name:NSViewFrameDidChangeNotification object:self.view];
		}
	}
	return self;
}

/*
 
 init
 
 */

- (id)initWithNibName:(NSString *)nibNameOrNil
{
	// load  nib from class bundle.
	// this will ensure that we search the plugins bundle rather than the main bundle
	return [self initWithNibName:nibNameOrNil bundle:[NSBundle bundleForClass:[self class]]];
}

/*
 
 - loadView
 
 */
- (void)loadView
{
	[super loadView];
	//[self.view setPostsFrameChangedNotifications:YES];
	oldFrameSize = self.view.frame.size;
}

/*
 
 can drag height
 
 */
- (BOOL)canDragHeight
{
	return NO;
}


/*
 
 update model notification
 
 */
- (void)updateModel:(NSNotification *)notification
{ 
    if ([notification object] == [[self view] window]) {
		[self updatePlist];
		[self processPlist:MGSProcessParameterPlistForSave];
	}
}

/*
 
 can drag middle view
 
 */
- (BOOL)canDragMiddleView
{
	return NO;
}

/*
 
 plist
 
 */
- (NSMutableDictionary *)plist
{
	return _plist;
}

/*
 
 set parameter plist
 
 */
- (BOOL)setParameterPlist:(NSMutableDictionary *)plist
{
	// validate the plist
	if (plist) {
		if (![plist isKindOfClass:[NSDictionary class]]) {
			MLog(RELEASELOG, @"plist is not NSDictionary"); 
			return NO;
		}
		
		if (![NSPropertyListSerialization propertyList:plist isValidForFormat:NSPropertyListXMLFormat_v1_0]) {
			MLog(RELEASELOG, @"invalid plist");
		}
	}
	_plist = plist;
	
	self.parameterValue = [self defaultValue];
	
	// ask the view to initialise itself from the new plist
	[self initialiseFromPlist];
	
	// update the plist so that default values are inserted
	if (plist) {
		[self updatePlist];
	}
	
	self.modelDataModified = NO;
	
	return YES;
}
/*
 
 parameter plist
 
 */
- (NSMutableDictionary *)parameterPlist
{
	// update the plist
	[self updatePlist];
	
	// return immutable copy
	return _plist;
}

/*
 
 initialise from plist
 
 */
- (void)initialiseFromPlist
{
	// default implementation does nothing.
	// subclasses can override to initialise.
}

/*
 
 update plist
 
 */
- (void)updatePlist
{
	// default implementation does nothing.
	// subclasses can override to update.
}

/*
 
 process plist
 
 */
- (void)processPlist:(MGSProcessParameterPlist)processOperation
{
	//MLog(DEBUGLOG, @"parameter plist before process: %@", _plist);
	
	switch (processOperation) {
		case MGSProcessParameterPlistForSave:
			break;
			
		default:
			NSAssert(NO, @"Invalid parameter plist process operation");
			break;
	}
	
	//MLog(DEBUGLOG, @"parameter plist after process: %@", _plist);
}

/* 
 
 awake from nib
 
 */
- (void)awakeFromNib
{
	// initialise from the current plist.
	// this will ensure that even if subclasses define no plist
	// that, if they are properly implemented, they will initialise to their correct defaults
	if (YES) {
		[self initialiseFromPlist];
	}
}

// this will be called by the binding machinery to
// modify the model data
- (void)setValue:(id)value forKeyPath:(NSString *)keyPath
{

	[super setValue:value forKeyPath:keyPath];
	self.modelDataModified = YES;
}

/*
 
 model data modified
 
 */
- (void)setModelDataModified:(BOOL)modified
{
	_modelDataModified = modified;
	if (_modelDataModified ) {

		NSWindow *window = [[self view] window];
		
		// set document edited for app window when modify model data
		if (_updatesDocumentEdited) {
			
			[window setDocumentEdited:YES];
			
		} else {
			
			// notify that model data has been modified
			[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteActionInputModified object:window userInfo:nil];
		}
	}
}

/*
 
 default value 
 
 */
- (id)defaultValue
{
	return [_plist objectForKey:MGSScriptKeyDefault];
}

/*
 
 set default value
 
 */
- (void)setDefaultValue:(id)value
{
	[_plist setObject:value forKey:MGSScriptKeyDefault];
}

/*
 
 reset to default value
 
 */
- (void)resetToDefaultValue
{
	[self commitEditing];
	self.parameterValue = [self defaultValue];
}

/*
 
 set parameter value
 
 */
- (void)setParameterValue:(id)newValue
{
	_parameterValue = newValue;
	BOOL defaultSelected = NO;
	
	// check if default selected
	if (_parameterValue == nil && [self defaultValue] == nil) {
		defaultSelected = YES;
	} else {
		defaultSelected = [_parameterValue isEqual:[self defaultValue]];
	}
	self.defaultValueSelected = defaultSelected;
}

/*
 
 - updateSubview:resize:
 
 */
- (void)updateSubview:(NSView *)subView resize:(BOOL)resize
{
	if ([[self.view subviews] count] > 0) {
		for (NSView *aSubView in [self.view subviews]) {
			[aSubView removeFromSuperview];
		}
	}
	
	// resize view to same height as subview
	if (resize) {
		[self updateFrameSize:NSMakeSize(self.view.frame.size.width, subView.frame.size.height)];
	}
	[self.view addSubview:subView];
	[subView setFrameOrigin:NSMakePoint(0, 0)];
	[subView setFrameSize:[self.view frame].size];
}

/*
 
 - updateFrameSize:
 
 */
- (void)updateFrameSize:(NSSize)newSize
{
	if (self.view.superview && delegate && [delegate respondsToSelector:@selector(pluginViewWantsNewSize:)]) {
		[delegate pluginViewWantsNewSize:newSize];
	}
}

/*
 
 - viewFrameDidChange:
 
 */
- (void)viewFrameDidChange:(NSNotification *)note
{
#pragma unused(note)
	
	if (self.view.superview && delegate && [delegate respondsToSelector:@selector(parameterSubViewDidResize:oldSize:)]) {
		[delegate parameterSubViewDidResize:self oldSize:oldFrameSize];
	}
	oldFrameSize = self.view.frame.size;
}

@end
