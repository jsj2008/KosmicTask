//
//  MGSFilePathParameterEditViewController.m
//  KosmicTask
//
//  Created by Mitchell Jonathan on 15/08/2011.
//  Copyright 2011 Mugginsoft. All rights reserved.
//

#import "MGSFilePathParameterEditViewController.h"

@implementation MGSFilePathParameterEditViewController

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        self.parameterDescription = NSLocalizedString(@"Select file path. File path will be sent to the task.", @"File selection prompt");
    }
    
    return self;
}

@end
