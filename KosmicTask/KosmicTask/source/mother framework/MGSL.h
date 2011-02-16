//
//  MGSL.h
//  Mother
//
//  Created by Jonathan on 29/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSAPLicence.h"

typedef enum _MGSLType {
	MGSLTypeIndividual = 0x0,	// individual licence
	MGSLTypeComputer = 0x01,	// computer licence
} MGSLType;


@interface MGSL : NSObject {
	NSString *_path;
	NSDictionary *_dictionary;
	NSData *_data;
}

+ (NSNumber *)defaultType;

- (BOOL)valid;
- (NSDictionary *)dictionary;
- (id)initWithPath:(NSString *)path;
- (id)plist;
- (id)initWithPlist:(id)plist;
- (BOOL)isTrial;
- (NSData *)data;
- (NSString *)owner;
- (NSString *)seats;
- (NSUInteger)seatCount;
- (NSString *)hash;
- (NSString *)path;
- (NSString *)optionDictPath;
- (NSNumber *)type;

- (id)dataSource;
@end
