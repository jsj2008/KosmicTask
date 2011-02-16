#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#include "MGSKosmicTaskQuicklook.h"

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
	#pragma unused(thisInterface)
	#pragma unused(contentTypeUTI)
	#pragma unused(options)
	
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	// get rtf data
	NSData *rtf = GetScriptRTFForURL((NSURL *)url);
	if (!rtf) {
		goto done;
	}
	
	// generate RTF preview
    QLPreviewRequestSetDataRepresentation(preview, (CFDataRef)rtf, kUTTypeRTF, NULL);

done:
    [pool release];
    return noErr;
}

void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview)
{
	#pragma unused(thisInterface)
	#pragma unused(preview)
    // implement only if supported
}
