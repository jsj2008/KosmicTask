#import "MGSApplication.h"

@implementation MGSApplication

/*- (void)orderFrontStandardAboutPanel:(id)sender
{
	// ctrl click required to show debug panel
	unsigned int flags = [[NSApp currentEvent] modifierFlags];
	if (flags & NSRightMouseDownMask) {
		[self showDebugPanel:self];
	} else {
		[super orderFrontStandardAboutPanel:sender];
	}
		
}*/

/*- (void) hideAboutPanel:(id)sender
{
	[aboutPanel orderOut:self];
	
	// ctrl click required to show debug panel
	unsigned int flags = [[NSApp currentEvent] modifierFlags];
	if (flags & NSControlKeyMask) {
		[self showDebugPanel:self];
	}
	
}*/


// override NSApplication reportException
#ifndef DEBUG
/*
- (void)reportException:(NSException *)theException
{
	id delegate = [self delegate];
	if ([delegate respondsToSelector:@selector(reportException:)]) {
		[delegate reportException:theException];
	}
	
}
 */
#endif

@end
