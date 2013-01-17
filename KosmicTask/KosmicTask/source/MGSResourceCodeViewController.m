//
//  MGSResourceCodeViewController.m
//  KosmicTask
//
//  Created by Jonathan on 17/01/2013.
//
//

#import "MGSResourceCodeViewController.h"

@interface MGSResourceCodeViewController ()

@end

@implementation MGSResourceCodeViewController

@synthesize editable, resourceEditable;

/*
 
 - initWithNibName:bundle:
 
 */
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        editable = NO;
        resourceEditable = NO;
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
    
	// fragaria
	[editorTextView bind:NSEditableBinding toObject:self withKeyPath:@"editable" options:nil];
	[editorTextView bind:[NSEditableBinding stringByAppendingString:@"2"] toObject:self withKeyPath:@"resourceEditable" options:nil];
}

#pragma mark -
#pragma mark Accessors

/*
 
 - string

 */
- (NSString *)string
{
    return [[fragaria string] copy];
}

/*
 
 - setString:
 
 */
- (void)setString:(NSString *)string
{
    [fragaria setString:string];
}

/*
 
 - setSyntaxDefinition:
 
 */
- (void)setSyntaxDefinition:(NSString *)syntaxDefinition
{
    [fragaria setObject:syntaxDefinition forKey:MGSFOSyntaxDefinitionName];
}
@end
