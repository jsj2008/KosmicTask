//
//  MGSTaskVariablesViewController.m
//  KosmicTask
//
//  Created by Jonathan on 06/04/2013.
//
//

#import "MGSTaskVariablesViewController.h"
#import "MGSScript.h"
#import "MGSParameterPluginController.h"
#import "MGSParameterPlugin.h"
#import "MGSScriptParameterManager.h"
#import "MGSAppController.h"
#import "MGSScriptParameterVariableStatusTransformer.h"
#import "MGSScriptParameterVariableNameUpdatingTransformer.h"

@interface MGSTaskVariablesViewController ()
@end

@implementation MGSTaskVariablesViewController

@synthesize script = _script;

#pragma mark -
#pragma mark Instance methods
/*
 
 - init
 
 */
- (id)init
{
	self = [super initWithNibName:@"TaskVariablesView" bundle:nil];
    if (self) {
        _taskVariablesArrayController = [[NSArrayController alloc] init];
    }
    
    return self;
}

#pragma mark -
#pragma mark Nib loading

/*
 
 - awakeFromNib
 
 */
- (void)awakeFromNib
{

}

#pragma mark -
#pragma mark Accessors

/*
 
 - setScript:
 
 */
- (void)setScript:(MGSScript *)script
{
    if (_script) {
        _script = nil;
    }
    if (!script) return;
    _script = script;
    
    // bind the task variables table view.
    // MGSFactoryArrayController does not support bindings.
    // hence we extract a factory array and bind to its content items.
    // its ro so we cannot and should not attempt to add new items.
    NSArray *scriptParameters = _script.parameterHandler.factoryArray;
    _taskVariablesArrayController.content = scriptParameters;
    MGSParameterPluginController *parameterPluginController = [(MGSAppController *)[NSApp delegate] parameterPluginController];
    
    // assign the index
    for (NSUInteger i = 0; i < [scriptParameters count]; i++) {
        MGSScriptParameter *scriptParameter = [scriptParameters objectAtIndex:i];
        scriptParameter.index = i + 1;
        MGSParameterPlugin *plugin = [parameterPluginController pluginWithClassName:scriptParameter.typeName];
        scriptParameter.typeDescription = [plugin menuItemString];
    }
    NSDictionary *bindingOptions = nil;
    NSTableColumn *tableCol = [_taskVariablesTableView tableColumnWithIdentifier:@"index"];
    [tableCol bind:NSValueBinding toObject:_taskVariablesArrayController withKeyPath:@"arrangedObjects.index" options:nil];
    
    tableCol = [_taskVariablesTableView tableColumnWithIdentifier:@"name"];
    [tableCol bind:NSValueBinding toObject:_taskVariablesArrayController withKeyPath:@"arrangedObjects.name" options:nil];
    
    tableCol = [_taskVariablesTableView tableColumnWithIdentifier:@"variable"];
    bindingOptions = @{NSValidatesImmediatelyBindingOption : @(YES)};
    [tableCol bind:NSValueBinding toObject:_taskVariablesArrayController withKeyPath:@"arrangedObjects.variableName" options:bindingOptions];
    
    tableCol = [_taskVariablesTableView tableColumnWithIdentifier:@"type"];
    [tableCol bind:NSValueBinding toObject:_taskVariablesArrayController withKeyPath:@"arrangedObjects.typeDescription" options:nil];
    
    tableCol = [_taskVariablesTableView tableColumnWithIdentifier:@"status"];
    bindingOptions = @{NSValueTransformerBindingOption:[[MGSScriptParameterVariableStatusTransformer alloc] init]};
    [tableCol bind:NSValueBinding toObject:_taskVariablesArrayController withKeyPath:@"arrangedObjects.variableStatus" options:bindingOptions];

    //tableCol = [_taskVariablesTableView tableColumnWithIdentifier:@"update"];
    //bindingOptions = @{NSValueTransformerBindingOption:[[MGSScriptParameterVariableNameUpdatingTransformer alloc] init]};
    
    // the table column cell is an NSPopupButtonCell that we have to bind to
    // though the column see : https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/CocoaBindings/Tasks/onerelation.html
    // this means that we have to use an NSTableColumnBinding such as value.
    //
    // so bindings are not a great solution here unless NSString value binding is used
    //
    //[tableCol bind:NSSelectedTagBinding toObject:_taskVariablesArrayController withKeyPath:@"arrangedObjects.variableNameUpdating" options:nil];

}

#pragma mark -
#pragma mark NSTableView delegate
/*
 
 - tableView:dataCellForTableColumn:row:
 
 */
- (NSCell *)tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    // http://www.corbinstreehouse.com/blog/2008/01/cocoa-willdisplaycell-delegate-method-of-nstableview-nscell-settextcolor-and-source-lists/
    NSTextFieldCell *cell = [tableColumn dataCell];
    if ([tableView selectedRow] == row) {
        
        //[cell setTextColor: [NSColor whiteColor]];
    } else {
        //[cell setTextColor: [NSColor blackColor]];
    }
    return cell;
}
/*
 
 - tableView:willDisplayCell:forTableColumn:row:
 
 */
- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
#pragma unused(tableView)
    
    // update column
    if ([[tableColumn identifier] isEqualToString:@"update"]) {
        if ([cell isKindOfClass:[NSPopUpButtonCell class]]) {
             MGSScriptParameter *scriptParameter = [[_taskVariablesArrayController arrangedObjects] objectAtIndex:(NSUInteger)row];
            [cell selectItemWithTag:scriptParameter.variableNameUpdating];
        }
        return;
    }
}

/*
 
 - controlTextDidEndEditing:
 
 */
- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
#pragma unused(aNotification)
    
    // called when cell edit ends.
    // NSTableView -clickedRow is -1 hence use selectedRow
    NSInteger row = [_taskVariablesTableView selectedRow];
    if (row == -1) return;
    
    // variable changed by hand, we don't want to overwrite this so set variable name updating to manual
    MGSScriptParameter *scriptParameter = [[_taskVariablesArrayController arrangedObjects] objectAtIndex:(NSUInteger)row];
    scriptParameter.variableNameUpdating = MGSScriptParameterVariableNameUpdatingManual;
    [_taskVariablesTableView setNeedsDisplayInRect:[_taskVariablesTableView rectOfRow:row]];
}
#pragma mark -
#pragma mark Actions

/*
 
 - popUpButtonMenuItemSelected:
 
 */
- (IBAction)popUpButtonMenuItemSelected:(id)sender
{
	// popup button cell menu item is sender
	if ([sender isKindOfClass:[NSMenuItem class]]) {
		
		NSInteger row = [_taskVariablesTableView clickedRow];
		if (row == -1) return;
		
        MGSScriptParameter *scriptParameter = [[_taskVariablesArrayController arrangedObjects] objectAtIndex:(NSUInteger)row];
        scriptParameter.variableNameUpdating = [(NSMenuItem *)sender tag];
	}
}


/*
 
 - variableNameChanged:
 
 */
- (IBAction)variableNameChanged:(id)sender
{
#pragma unused(sender)
    NSInteger row = [_taskVariablesTableView clickedRow];
    if (row == -1) return;
    
    // variable changed by hand, we don't want to overwrite this so set to manual
    MGSScriptParameter *scriptParameter = [[_taskVariablesArrayController arrangedObjects] objectAtIndex:(NSUInteger)row];
    scriptParameter.variableNameUpdating = MGSScriptParameterVariableNameUpdatingManual;
    [_taskVariablesTableView setNeedsDisplayInRect:[_taskVariablesTableView rectOfRow:row]];
}
@end


