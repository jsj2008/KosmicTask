/* ApplicationDelegate */

#import <Cocoa/Cocoa.h>
#import "NDScript.h"

@class			LoggingObject,
					BaseTestClass;

@interface ApplicationDelegate : NSWindowController
{
	IBOutlet NSTextView		* logTextView;
	IBOutlet NSButtonCell	* runButton;
	IBOutlet NSButtonCell	* clearButton;
	IBOutlet NSButtonCell	* selectAllButton;
	IBOutlet NSButtonCell	* deselectAllButton;
	IBOutlet NSButton		* repeatButton;
	IBOutlet NSTextField	* repeatValueField;
	IBOutlet NSMatrix 		* testCheckBoxMatrix;
	IBOutlet NSTextField	* runningTestNameField;
	IBOutlet NSTextField	* runningTestCountField;
	IBOutlet NSTextField	* errorCountField;
	IBOutlet NSButton		* numberOfScriptLoggingButton;
	IBOutlet NSTextField	* garbageCollectionEnabledField;
@private
	NSMutableDictionary		* testObjects;
	LoggingObject			* loggingObject;
	BOOL					commandKeyTest,
							stopRepeat;
	int						runCount,
							errorCount,
							repeatCount,
							testNumber;
}

- (IBAction)runTests:(id)sender;
- (IBAction)clearLogs:(id)sender;
- (IBAction)clearNumberOfScriptLoggins:(id)sender;
- (IBAction)selectAll:(id)sender;
- (IBAction)deselectAll:(id)sender;
- (IBAction)selectedTestChanged:(id)sender;
- (IBAction)repeatChanged:(id)sender;

- (void)runTestEntry:(NSTimer *)timer;
- (void)finishedTest:(id)ignored;
- (void)createTests;
- (void)enableRunButton:(BOOL)enable;
- (BOOL)runTestNamed:(NSString *)name;
- (void)addSeparatorName:(NSString *)name;
- (BOOL)addTest:(BaseTestClass *)test withNamed:(NSString *)name selected:(BOOL)selected;
- (void)logMessage:(NSString *)string;
- (void)errorMessage:(NSString *)string;
- (NSString *)logContent;
- (LoggingObject *)loggingObject;
- (void)logScriptMessage:(NSString *)string;
- (void)logMessage:(NSString *)string withColor:(NSColor *)color;
- (void)setRunningTestName:(NSString *)name;
- (void)setRunningTestCount:(unsigned int)index outOfTotal:(unsigned int)count;
- (void)increamentErrorCount;
- (void)resetErrorCount;

@end
