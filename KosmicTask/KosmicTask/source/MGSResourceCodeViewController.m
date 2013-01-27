//
//  MGSResourceCodeViewController.m
//  KosmicTask
//
//  Created by Jonathan on 17/01/2013.
//
//

#import "MGSResourceCodeViewController.h"
#import "MGSLanguageTemplateResource.h"
#import "MGSScript.h"
#import "MGSLanguageFunctionDescriptor.h"
#import "MGSLanguagePlugin.h"
#import "MLog.h"

@interface MGSResourceCodeViewController ()
- (void)setViewString:(NSString *)string;
- (void)setSyntaxDefinition:(NSString *)syntaxDefinition;
- (void)updateCodeDisplay;
- (void)updateSyntaxDefinition;
- (void)updateCodeSegmentControl;
- (NSString *)stringForCodeSegmentIndex:(MGSCodeSegmentIndex)segmentIndex;

@property BOOL textViewEditable;
@property BOOL textEditable;

@end

char MGSTextViewEditableContext;

@implementation MGSResourceCodeViewController

@synthesize textViewEditable;

@synthesize editable, resourceEditable, languageTemplateResource, script, documentEdited, selectedCodeSegmentIndex, delegate, textEditable;

/*
 
 - initWithNibName:bundle:
 
 */
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        editable = NO;
        resourceEditable = NO;
        selectedCodeSegmentIndex = kMGSScriptCodeSegmentIndex;
    }
    
    return self;
}


#pragma mark -
#pragma mark Nib
/*
 
 - awakeFromNib
 
 */
- (void)awakeFromNib
{
	// create Fragaria instance
	fragaria = [[MGSFragaria alloc] init];
	
	//
	// define initial object configuration
	//
	// see MGSFragaria.h for details
	//
	[fragaria setObject:[NSNumber numberWithBool:YES] forKey:MGSFOIsSyntaxColoured];
	[fragaria setObject:[NSNumber numberWithBool:YES] forKey:MGSFOShowLineNumberGutter];
	[fragaria setObject:self forKey:MGSFODelegate];
	
	// embed in our host view
	[fragaria embedInView:editorHostView];
	editorTextView = [fragaria objectForKey:ro_MGSFOTextView];
	    
    // turn off auto text replacement for items such as ...
    // as it can cause certain scripts to fail to build e.g: Python
    [editorTextView setAutomaticDataDetectionEnabled:NO];
	[editorTextView setAutomaticTextReplacementEnabled:NO];
    
	// bindings    
    [editorTextView bind:NSEditableBinding toObject:self withKeyPath:@"textViewEditable" options:nil];
    [codeSegmentedControl bind:NSSelectedIndexBinding toObject:self withKeyPath:@"selectedCodeSegmentIndex" options:nil];
    
    [self addObserver:self forKeyPath:@"editable" options:0 context:&MGSTextViewEditableContext];
    [self addObserver:self forKeyPath:@"resourceEditable" options:0 context:&MGSTextViewEditableContext];
    [self addObserver:self forKeyPath:@"textEditable" options:0 context:&MGSTextViewEditableContext];
    
    self.selectedCodeSegmentIndex  = kMGSScriptCodeSegmentIndex;
    
    [self updateCodeSegmentControl];
}

#pragma mark -
#pragma mark Accessors

/*
 
 - observeValueForKeyPath:ofObject:change:context:
 
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
#pragma unused(keyPath)
#pragma unused(object)
#pragma unused(change)
    
    if (context == &MGSTextViewEditableContext) {
        self.textViewEditable = self.resourceEditable && self.editable && self.textEditable;
    }
}
#pragma mark -
#pragma mark Accessors

/*
 
 - setSelectedCodeSegmentIndex:
 
 */
- (void)setSelectedCodeSegmentIndex:(MGSCodeSegmentIndex)theIndex
{
    // if template has been edited the we need to save the resource
    if (self.documentEdited && selectedCodeSegmentIndex == kMGSTemplateCodeSegmentIndex) {
        if ([self.delegate respondsToSelector:@selector(saveDocument:)]) {
            [self.delegate saveDocument:self];
        }
    }

    switch (theIndex) {
        case kMGSScriptCodeSegmentIndex:
            self.textEditable = NO;
            break;
            
        case kMGSTemplateCodeSegmentIndex:
            self.textEditable = YES;
            break;
            
        case kMGSVariablesCodeSegmentIndex:
            self.textEditable = NO;
            break;
        default:
            return;
    }

    selectedCodeSegmentIndex = theIndex;
    [self updateCodeDisplay];
}
/*
 
 - setLanguageTemplateResource:
 
 */
- (void)setLanguageTemplateResource:(MGSLanguageTemplateResource *)resource
{
    languageTemplateResource = resource;
    
    [self updateCodeDisplay];
}

/*
 
 - updateCodeDisplay
 
 */
- (void)updateCodeDisplay
{
    NSString *stringResource = [self stringForCodeSegmentIndex:selectedCodeSegmentIndex];
    [self setViewString:stringResource];
    [self updateSyntaxDefinition];
}
/*
 
 - stringForCodeSegmentIndex
 
 */
- (NSString *)stringForCodeSegmentIndex:(MGSCodeSegmentIndex)segmentIndex
{
    NSString *stringResource = @"";
    
    if (segmentIndex == kMGSScriptCodeSegmentIndex ||
        segmentIndex == kMGSVariablesCodeSegmentIndex) {
        /*
         
         the template system will raise an execption if the template cannot be processed
         
         */
        @try {
            stringResource = @"\n[template could not be rendered - see log for details]";
            
            MGSLanguageFunctionDescriptor *descriptor = [[MGSLanguageFunctionDescriptor alloc] initWithScript:self.script];
            NSMutableDictionary *templateVariables = [descriptor templateVariables];
            
            NSString *entryCodeString = [descriptor generateTaskFunctionCodeString];
            if (entryCodeString) {
                [templateVariables setObject:entryCodeString forKey:@"task-function"];
            }
            
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setTimeStyle:kCFDateFormatterShortStyle];
            [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
            NSString *date = [dateFormatter stringFromDate:[NSDate date]];
            
            NSDictionary *variables = [NSDictionary dictionaryWithObjectsAndKeys:
                                       [MGSScript defaultAuthor], @"author",
                                       script.scriptType, @"script",
                                       date, @"date",
                                       nil];
            [templateVariables addEntriesFromDictionary:variables];
            
            if (segmentIndex == kMGSScriptCodeSegmentIndex) {
                stringResource = [languageTemplateResource stringResourceWithVariables:templateVariables];
            } else {
                Class jsonClass = NSClassFromString(@"NSJSONSerialization");
                
                // display variables as JSON if possible
                if (jsonClass) {
                    NSError *jsonError = nil;
                    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:templateVariables options:NSJSONWritingPrettyPrinted error:&jsonError];
                    if (!jsonData) {
                        stringResource = [jsonError description];
                    } else {
                        stringResource = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                    }
                    
                } else {
                    stringResource = [templateVariables description];
                }
            }
            
        } @catch (NSException *e) {
            MLogInfo(@"Exception: %@", e);
        }
    } else {
        stringResource = [languageTemplateResource stringResource];
    }
    
    return stringResource;
}
/*
 
 - Script:
 
 */
- (void)setScript:(MGSScript *)theScript
{
    script = theScript;

    [self updateSyntaxDefinition];
}
/*
 
 - scriptString
 
 */
- (NSString *)scriptString
{
    NSString *theString = nil;
    
    if (self.selectedCodeSegmentIndex == kMGSScriptCodeSegmentIndex) {
       theString = [[fragaria string] copy];
    } else {
        theString = [self stringForCodeSegmentIndex:kMGSScriptCodeSegmentIndex];
    }
    
    return theString;
}
/*
 
 - setViewString:
 
 */
- (void)setViewString:(NSString *)string
{
    if (!string) {
        string = @"";
    }
    [fragaria setString:string];
}
/*
 
 - setSyntaxDefinition:
 
 */
- (void)setSyntaxDefinition:(NSString *)syntaxDefinition
{
    [fragaria setObject:syntaxDefinition forKey:MGSFOSyntaxDefinitionName];
}

/*
 
 - setTextViewEditable:
 
 */
- (void)setTextViewEditable:(BOOL)value
{
    textViewEditable = value;
    [self updateCodeSegmentControl];
}
#pragma mark -
#pragma mark User interface
/*
 
 - updateCodeSegmentControl
 
 */
- (void)updateCodeSegmentControl
{
    NSString *scriptCodeSegmentTitle = nil;
    NSString *templateCodeSegmentTitle = nil;
    if (self.textViewEditable) {
        scriptCodeSegmentTitle = NSLocalizedString(@"Code", @"");
        templateCodeSegmentTitle = NSLocalizedString(@"Edit", @"");
    } else {
        scriptCodeSegmentTitle = NSLocalizedString(@"Code", @"");
        templateCodeSegmentTitle = NSLocalizedString(@"Template", @"");
        
    }
    
    [codeSegmentedControl setLabel:scriptCodeSegmentTitle forSegment:kMGSScriptCodeSegmentIndex];
    [codeSegmentedControl setLabel:templateCodeSegmentTitle forSegment:kMGSTemplateCodeSegmentIndex];
    [codeSegmentedControl setNeedsDisplay];
}
#pragma mark -
#pragma mark Syntax management

/*
 
 - updateSyntaxDefinition
 
 */
- (void)updateSyntaxDefinition
{
    NSString *syntaxDefinition = @"none";
    
    switch (self.selectedCodeSegmentIndex) {
        case kMGSScriptCodeSegmentIndex:
        case kMGSTemplateCodeSegmentIndex:
            if (script) {
                syntaxDefinition = [script.languagePlugin syntaxDefinition];
            }
            break;
            
        default:
            break;
    }
    
    [self setSyntaxDefinition:syntaxDefinition];
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

#pragma mark -
#pragma mark NSViewController
/*
 
 - commitEditing
 
 */
- (BOOL)commitEditing
{
    BOOL success = [super commitEditing];
    
    // code text view is not bound so we commit our edit manually.
    
    // save template
    if (self.selectedCodeSegmentIndex == kMGSTemplateCodeSegmentIndex && self.documentEdited) {
        self.languageTemplateResource.stringResource = [[fragaria string] copy];
    }
    
    return success;
}

@end
