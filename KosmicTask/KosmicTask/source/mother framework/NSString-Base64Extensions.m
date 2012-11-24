// Copyright (c) 2006 Dave Dribin (http://www.dribin.org/dave/)
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
// 
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "NSString-Base64Extensions.h"
#include <openssl/bio.h>
#include <openssl/evp.h>

// openssl/bio.h defines BIO_set_flags differently for libcrypto.0.9.8.dylib
#define BIO_set_flags_097(b,f) ((b)->flags|=(f))

@implementation NSString (Base64)

- (NSData *) decodeBase64
{
    return [self decodeBase64WithNewlines: YES];
}

- (NSData *) decodeBase64WithNewlines: (BOOL) encodedWithNewlines
{
    // Create a memory buffer containing Base64 encoded string data
    BIO * mem = BIO_new_mem_buf((void *) [self cString], (int)[self cStringLength]);
    
    // Push a Base64 filter so that reading from the buffer decodes it
    BIO * b64 = BIO_new(BIO_f_base64());
    // MGS linker having problems with libcrypto.0.9.7.dylib
	// arising because BIO_set_flags is defined as a macro in 0.9.7 but as a function in 0.9.8
	// hence the liniking roblem when target 0.9.7. OS X 10.6 open ships with the 0.9.8 headers.
	if (!encodedWithNewlines) {
		BIO_set_flags(b64, BIO_FLAGS_BASE64_NO_NL);
		//BIO_set_flags_097(b64, BIO_FLAGS_BASE64_NO_NL);
	}
	
    mem = BIO_push(b64, mem);

    // Decode into an NSMutableData
    NSMutableData * data = [NSMutableData data];
    char inbuf[512];
    int inlen;
    while ((inlen = BIO_read(mem, inbuf, sizeof(inbuf))) > 0)
        [data appendBytes: inbuf length: inlen];
    
    // Clean up and go home
    BIO_free_all(mem);
    return data;
}

@end
