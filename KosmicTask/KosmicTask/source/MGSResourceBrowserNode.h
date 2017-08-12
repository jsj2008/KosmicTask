//
//  MGSResourceBrowserNode.h
//  KosmicTask
//
//  Created by Jonathan on 14/06/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MGSResourceBrowserNode : NSTreeNode <NSCopying> {
	NSImage *image;
	NSNumber *count;
	NSInteger counter;
	BOOL hasCount;
	NSImage *statusImage;
}

+ (void)registerClass:(Class)klass options:(NSDictionary *)options;
- (NSString *)name;
- (NSString *)description;
- (id)bindingObject;
- (NSMutableArray *)leaves;
- (id)ancestorNodeWithRepresentedClass:(Class)klass;
- (id)objectForKey:(id)optionKey;
- (NSComparisonResult)compare:(MGSResourceBrowserNode *)node;
- (NSString *)subrootDescription;

@property (strong) NSImage *image;
@property (strong) NSImage *statusImage;
@property (nonatomic) NSInteger counter;
@property BOOL hasCount;
@end
