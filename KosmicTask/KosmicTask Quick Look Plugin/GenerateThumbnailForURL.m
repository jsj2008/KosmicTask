#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#include <WebKit/WebKit.h>
#include "MGSKosmicTaskQuicklook.h"

//The minimum aspect ratio (width / height) of a thumbnail.
#define MINIMUM_ASPECT_RATIO (1.0/2.0)


/* -----------------------------------------------------------------------------
    Generate a thumbnail for file

   This function's job is to create thumbnail for designated file as fast as possible
   ----------------------------------------------------------------------------- */

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize mxSize)
{
	#pragma unused(thisInterface)
	#pragma unused(contentTypeUTI)
	#pragma unused(options)
	// see
	// http://ddribin.googlecode.com/svn/trunk/qlenscript/GenerateThumbnailForURL.m
	// or
	// http://github.com/n8gray/QLColorCode/blob/master/GenerateThumbnailForURL.m
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// get rtf data
	NSData *rtf = GetScriptRTFForURL((NSURL *)url);
	if (!rtf) {
		goto done;
	}
	
	// get attributed string
	NSAttributedString *attrString = [[[NSAttributedString alloc] initWithRTF:rtf documentAttributes:nil] autorelease];
	
	// get HTML
	NSError *error = nil;
	NSData *htmlData = [attrString 
					dataFromRange:NSMakeRange(0, [attrString length]) 
					documentAttributes:[NSDictionary dictionaryWithObjectsAndKeys: NSHTMLTextDocumentType, NSDocumentTypeDocumentAttribute, nil] 
					error:&error];
	if (!htmlData) {
		NSLog(@"Could not create HTML", nil);
		goto done;
	}
	
	// Render as though there is an 600x800 window, and fill the thumbnail 
    // vertically.  This code could be more general.  I'm assuming maxSize is
    // a square, though nothing horrible should happen if it isn't.
    
    NSRect renderRect = NSMakeRect(0.0f, 0.0f, 600.0f, 800.0f);
    CGFloat scale = mxSize.height/800.0f;
    NSSize scaleSize = NSMakeSize(scale, scale);
    CGSize thumbSize = NSSizeToCGSize(
									  NSMakeSize((mxSize.width * (600.0f/800.0f)), 
												 mxSize.height));	
	
	// create webview
	WebView* webView = [[[WebView alloc] initWithFrame:renderRect] autorelease];
    [webView scaleUnitSquareToSize:scaleSize];
    [[[webView mainFrame] frameView] setAllowsScrolling:NO];	
	
	// load webview
	[[webView mainFrame] loadData: htmlData
						 MIMEType: @"text/html"
				 textEncodingName: @"utf-8"
						  baseURL: nil];
	while([webView isLoading]) {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, true);
    }
    
    // Get a context to render into
    CGContextRef context = QLThumbnailRequestCreateContext(thumbnail, thumbSize, false, NULL);
    if(context != NULL) {
        NSGraphicsContext* nsContext = [NSGraphicsContext
										graphicsContextWithGraphicsPort:(void *)context 
										flipped:[webView isFlipped]];
        
		// render the webview
        [webView displayRectIgnoringOpacity:[webView bounds]
                                  inContext:nsContext];
        
        QLThumbnailRequestFlushContext(thumbnail, context);
        
        CFRelease(context);
    }

done:
    [pool release];
    return noErr;
}

void CancelThumbnailGeneration(void* thisInterface, QLThumbnailRequestRef thumbnail)
{
	#pragma unused(thisInterface)
	#pragma unused(thumbnail)
    // implement only if supported
}
