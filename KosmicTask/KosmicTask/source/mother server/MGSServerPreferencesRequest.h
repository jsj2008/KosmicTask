//
//  MGSServerPreferencesRequest.h
//  Mother
//
//  Created by Jonathan on 29/03/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MGSServerPreferencesRequest : NSObject {

}

+ (BOOL)parseDictionary:(NSDictionary *)preferences;
@end
