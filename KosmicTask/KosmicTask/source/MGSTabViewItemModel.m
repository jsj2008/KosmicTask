//
//  MGSTabViewItemModel.m
//  KosmicTask
//
//  Created by Jonathan on 18/02/2013.
//
//

#import "MGSTabViewItemModel.h"

@implementation MGSTabViewItemModel

@synthesize largeImage = _largeImage;
@synthesize icon = _icon;
@synthesize iconName = _iconName;

@synthesize isProcessing = _isProcessing;
@synthesize objectCount = _objectCount;
@synthesize isEdited = _isEdited;

- (id)init {
	if((self = [super init])) {
		_isProcessing = NO;
		_icon = nil;
		_iconName = nil;
        _largeImage = nil;
		_objectCount = 0;
		_isEdited = NO;
	}
	return self;
}

-(void)dealloc {
    
    _icon = nil;
    _iconName = nil;
    _largeImage = nil;
    
}

@end

