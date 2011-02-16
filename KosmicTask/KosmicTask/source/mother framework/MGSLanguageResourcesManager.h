//
//  MGSLanguageResourcesManager.h
//  KosmicTask
//
//  Created by Jonathan on 28/05/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSLanguageTemplateResource.h"
#import "MGSScript.h"
#import "MGSResourceBrowserNode.h"
#import "MGSResourcesManager.h"
#import "MGSLanguageTemplateResourcesManager.h"
#import "MGSLanguageDocumentResourcesManager.h"

@interface MGSLanguageResourcesManager : MGSResourcesManager {
	
	MGSLanguageTemplateResourcesManager *templateManager;
	MGSLanguageDocumentResourcesManager *documentManager;
}

@property (readonly) MGSLanguageTemplateResourcesManager *templateManager;
@property (readonly) MGSLanguageDocumentResourcesManager *documentManager;

@end
