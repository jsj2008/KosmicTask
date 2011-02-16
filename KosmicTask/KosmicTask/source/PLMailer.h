//
//  PLMailer.h
//  TestBed
//
//  Created by Paul Lynch on 12/02/2005.
//  Copyright 2005 P & L Systems. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *PLMailerUrlType;
extern NSString *PLMailerMailType;


@interface PLMailer : NSObject {
	
	NSString *type;
	NSString *to;
	NSString *cc;
	NSString *subject;
	NSAttributedString *body;
	NSString *from;

}

+ (PLMailer *)mailer;

// accessors

- (NSString *)type;
- (void)setType:(NSString *)value;

- (NSString *)to;
- (void)setTo:(NSString *)value;

- (NSString *)cc;
- (void)setCc:(NSString *)value;

- (NSString *)subject;
- (void)setSubject:(NSString *)value;

- (NSAttributedString *)body;
- (NSString *)bodyString;
- (void)setBody:(NSAttributedString *)value;

- (NSString *)from;
- (void)setFrom:(NSString *)value;

	// actions

- (IBAction) send:(id)sender;

// private API
- (void)sendUrlEmail;
//- (void)sendMailEmail;

@end
