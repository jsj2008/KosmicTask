//
//  MGSPDFExportPlugin.m
//  Mother
//
//  Created by Jonathan on 20/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSPDFExportPlugin.h"


@implementation MGSPDFExportPlugin

/* 
 
 file extension
 
 */
- (NSString *)fileExtension
{
	return @"pdf";
}

/* 
 
 menu item string
 
 */
- (NSString *)menuItemString
{
	return NSLocalizedString(@"Portable Document Format (PDF)", @"Export plugin menu item string");
}

/*
 
 export view
 
 */
- (NSString *)exportView:(NSView *)aView toPath:(NSString *)path
{
	BOOL success = NO;
	
	@try {
		
		// see this for PDF info: http://cocoadevcentral.com/articles/000074.php
		
		// make sure path is complete, including extension
		path = [self completePath:path];

		// shared print info
		NSPrintInfo *sharedInfo = [NSPrintInfo sharedPrintInfo];
		NSMutableDictionary *sharedDict = [sharedInfo dictionary];
		NSMutableDictionary *printInfoDict = [NSMutableDictionary dictionaryWithDictionary:
						 sharedDict];
		[printInfoDict setObject:NSPrintSaveJob 
						  forKey:NSPrintJobDisposition];
		[printInfoDict setObject:path forKey:NSPrintSavePath];
		
		// print info
		NSPrintInfo *printInfo = [[NSPrintInfo alloc] initWithDictionary: printInfoDict];
		
		// note it prove beneficial to provide a customization panel here
		[printInfo setHorizontalPagination: NSFitPagination];	// one page wide
		[printInfo setVerticalPagination: NSAutoPagination];
		[printInfo setVerticallyCentered:NO];
		
		// print to PDF
		NSPrintOperation *printOp = [NSPrintOperation printOperationWithView:aView 
												 printInfo:printInfo];
		[printOp setShowsPrintPanel:NO];
		
		// note that this blocks the current thread.
		// see - (void)runOperationModalForWindow:(NSWindow *)docWindow delegate:(id)delegate didRunSelector:(SEL)didRunSelector contextInfo:(void *)contextInfo
		// for threaded solution
		success = [printOp runOperation];

	} @catch (NSException *e) {
		[self onException:e path:path];
	}
	
	return success ? path : nil;
}

@end
