//
//  MGSAboutWindowController.h
//  Mother
//
//  Created by Jonathan on 24/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WebKit/WebView.h"

@interface MGSAboutWindowController : NSWindowController {
	NSString *_version;
	NSString *_build;
	NSString *_licensedTo;
	NSAttributedString *_credits;
	//IBOutlet WebView *_webview;
	//IBOutlet NSTextView *_creditsTextView;
	NSString *_appCodeSignatureStatus;
	NSString *_serverCodeSignatureStatus;
	NSString *_taskCodeSignatureStatus;
}

+ (MGSAboutWindowController *) sharedInstance;

@property (assign) NSString *version;
@property (assign) NSString *build;
@property (assign) NSString *licensedTo;
@property (assign) NSAttributedString *credits;
@property (assign) NSString *appCodeSignatureStatus;
@property (assign) NSString *serverCodeSignatureStatus;
@property (assign) NSString *taskCodeSignatureStatus;
@end
