//
//  MGSTabViewItemModel.h
//  KosmicTask
//
//  Created by Jonathan on 18/02/2013.
//
//

#import <Cocoa/Cocoa.h>

@interface MGSTabViewItemModel : NSObject {

	BOOL        _isProcessing;
	NSImage     *_icon;
    NSImage     *_largeImage;
	NSString    *_iconName;
	NSInteger   _objectCount;
	BOOL        _isEdited;
}

@property (retain) NSImage *largeImage;
@property (retain) NSImage *icon;
@property (retain) NSString *iconName;

@property (assign) BOOL isProcessing;
@property (assign) NSInteger objectCount;
@property (assign) BOOL isEdited;

// designated initializer
- (id)init;

@end