//
//  MGSCodeSigning.h
//  Mother
//
//  Created by Jonathan on 27/10/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

enum _CodesignResult {
	CodesignUnrecognised = -2,
	CodesignError = -1,
	CodesignOkay = 0,
	CodesignFail = 1,
	CodesignInvalidArgs = 2,
	CodesignFailedRequirement = 3,
};
typedef NSInteger CodesignResult;

@interface MGSCodeSigning : NSObject {
	NSString *_resultString;
}

@property (copy) NSString *resultString;

- (CodesignResult)validateExecutable;
- (CodesignResult)validatePath:(NSString *)path;
- (CodesignResult)validateApplication;

@end
