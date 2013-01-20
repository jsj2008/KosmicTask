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
- (void)setString:(NSString *)string;
- (void)setSyntaxDefinition:(NSString *)syntaxDefinition;
- (void)updateCodeDisplay;
@end

@implementation MGSResourceCodeViewController

@synthesize editable, resourceEditable, languageTemplateResource, script, documentEdited, selectedCodeSegmentIndex, templateDisplayed, delegate;

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
	[editorTextView bind:NSEditableBinding toObject:self withKeyPath:@"editable" options:nil];
	[editorTextView bind:[NSEditableBinding stringByAppendingString:@"2"] toObject:self withKeyPath:@"resourceEditable" options:nil];
    [editorTextView bind:[NSEditableBinding stringByAppendingString:@"3"] toObject:self withKeyPath:@"templateDisplayed" options:nil];
    [codeSegmentedControl bind:NSSelectedIndexBinding toObject:self withKeyPath:@"selectedCodeSegmentIndex" options:nil];
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

    NSString *scriptCodeSegmentTitle = nil;
    NSString *templateCodeSegmentTitle = nil;
    if (self.resourceEditable) {
        scriptCodeSegmentTitle = NSLocalizedString(@"View", @"");
        templateCodeSegmentTitle = NSLocalizedString(@"Edit", @"");
    } else {
        scriptCodeSegmentTitle = NSLocalizedString(@"Script", @"");
        templateCodeSegmentTitle = NSLocalizedString(@"Template", @"");
        
    }
    
    switch (theIndex) {
        case kMGSScriptCodeSegmentIndex:
            self.templateDisplayed = NO;
            break;
            
        case kMGSTemplateCodeSegmentIndex:
            self.templateDisplayed = YES;
            break;
            
        default:
            return;
    }
    
    [codeSegmentedControl setLabel:scriptCodeSegmentTitle forSegment:kMGSScriptCodeSegmentIndex];
    [codeSegmentedControl setLabel:templateCodeSegmentTitle forSegment:kMGSTemplateCodeSegmentIndex];
    
    selectedCodeSegmentIndex = theIndex;
    [self updateCodeDisplay];
}
/*
 
 - string

 */
- (NSString *)string
{
    return [[fragaria string] copy];
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
    NSString *stringResource = @"";
    
    if (selectedCodeSegmentIndex == kMGSScriptCodeSegmentIndex) {
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
            
            stringResource = [languageTemplateResource stringResourceWithVariables:templateVariables];
            
        } @catch (NSException *e) {
            MLogInfo(@"Exception: %@", e);
        }
    } else {
        stringResource = [languageTemplateResource stringResource];
    }
    
    [self setString:stringResource];
    
}
/*
 
 - Script:
 
 */
- (void)setScript:(MGSScript *)theScript
{
    script = theScript;
    
    // set text syntax definition
    NSString *syntaxDefinition = [script.languagePlugin syntaxDefinition];
    [self setSyntaxDefinition:syntaxDefinition];
}
/*
 
 - setString:
 
 */
- (void)setString:(NSString *)string
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
    
    // code text view is not bound so we commit our edit manually
    self.languageTemplateResource.stringResource = self.string;

    return success;
}

@end
