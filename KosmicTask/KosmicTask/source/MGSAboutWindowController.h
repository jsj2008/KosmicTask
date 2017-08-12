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

@property (strong) NSString *version;
@property (strong) NSString *build;
@property (strong) NSString *licensedTo;
@property (strong) NSAttributedString *credits;
@property (strong) NSString *appCodeSignatureStatus;
@property (strong) NSString *serverCodeSignatureStatus;
@property (strong) NSString *taskCodeSignatureStatus;
@end
