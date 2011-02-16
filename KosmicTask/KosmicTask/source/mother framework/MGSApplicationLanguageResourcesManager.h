//
//  MGSApplicationLanguageResourcesManager.h
//  KosmicTask
//
//  Created by Jonathan on 30/06/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "MGSLanguageResourcesManager.h"
#import "MGSLanguagePropertiesResourcesManager.h"

@interface MGSApplicationLanguageResourcesManager : MGSLanguageResourcesManager {
	MGSLanguagePropertiesResourcesManager *settingsManager;
}

@property (readonly) MGSLanguagePropertiesResourcesManager *settingsManager;

@end
