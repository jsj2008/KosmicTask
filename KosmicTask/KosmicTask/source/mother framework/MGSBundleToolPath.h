//
//  MGSBundleToolPath.h
//  Mother
//
//  Created by Jonathan on 06/12/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSPath.h"

@interface MGSBundleToolPath : MGSPath {

}

+ (NSString *)appPackageParentPath;
+ (NSString *)appPackagePath;
+ (NSString *)toolPath;

@end
