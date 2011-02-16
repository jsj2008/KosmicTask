//
//  MGSUser.h
//  Mother
//
//  Created by Jonathan on 31/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Collaboration/Collaboration.h>

@interface MGSUser : NSObject {
	CBIdentity *_user;
}

+ (id)currentUser;
- (id)initWithName:(NSString *)name;
- (BOOL)isMemberOfAdminGroup;

@end
