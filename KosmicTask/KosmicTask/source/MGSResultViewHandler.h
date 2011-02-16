//
//  MGSResultViewHandler.h
//  Mother
//
//  Created by Jonathan on 06/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MGSTaskSpecifier;

@interface MGSResultViewHandler : NSObject {
	IBOutlet NSScrollView *scrollView;
	NSMutableArray *_resultViewControllers;
}

+ (id)defaultResultObject;
- (void)addResult1:(id)resultObject forAction:(MGSTaskSpecifier *)action;

@end
