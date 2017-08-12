//
//  PLMailer.m
//  TestBed
//
//  Created by Paul Lynch on 12/02/2005.
//  Copyright 2005 P & L Systems. All rights reserved.
//

#import "PLMailer.h"

@implementation PLMailer

NSString *PLMailerUrlType = @"PLMailerURLType";
NSString *PLMailerMailType = @"PLMailerNSMailDeliveryType";

+ (PLMailer *)mailer {
	return [[PLMailer alloc] init];
}

- (id)init {
	type = PLMailerUrlType;
	to = @"";
	cc = @"";
	subject = @"";
	body = [[NSAttributedString alloc] initWithString:@""];
	from = @"";
	return self;
}


// accessors
- (NSString *)type {
	return type;
}
- (void)setType:(NSString *)value {
	type = value;
}

- (NSString *)to {
	return to;
}
- (void)setTo:(NSString *)value {
	to = value;
}

- (NSString *)cc {
	return cc;
}
- (void)setCc:(NSString *)value {
	cc = value;
}

- (NSString *)subject {
	return subject;
}
- (void)setSubject:(NSString *)value {
	subject = value;
}

- (NSAttributedString *)body {
	return body;
}
- (NSString *)bodyString {
	return [body string];
}
- (void)setBody:(NSAttributedString *)value {
	body = value;
}

- (NSString *)from {
	return from;
}
- (void)setFrom:(NSString *)value {
	from = value;
}

// actions

- (IBAction) send:(id)sender {
	#pragma unused(sender)
	
	if ([type isEqualToString:PLMailerUrlType]) {
		[self sendUrlEmail];
	}
	if ([type isEqualToString:PLMailerMailType]) {
		//[self sendMailEmail];
	}
	// better not get here
}

- (NSArray *)ccArray {
	NSArray *array = [[self cc] componentsSeparatedByString:@","];
	return array;
}

// copied wholesale from "Cocoa Programming", by Scott, Erik and Don

- (void)sendUrlEmail {
	NSString *encodedSubject = [NSString stringWithFormat:@"SUBJECT=%@",
		[[self subject] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
	NSString *encodedBody = [NSString stringWithFormat:@"BODY=%@",
		[[self bodyString] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
	NSString *encodedTo = [[self to] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
	NSString *encodedURLString = [NSString stringWithFormat:@"mailto:%@?%@&%@",
		encodedTo, encodedSubject, encodedBody];
	NSURL *mailtoURL = [NSURL URLWithString:encodedURLString];
	[[NSWorkspace sharedWorkspace] openURL:mailtoURL];
}

@end
