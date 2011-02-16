//
//  MGSRequestProgress.h
//  Mother
//
//  Created by Jonathan on 01/02/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "MGSNetRequest.h"

typedef enum _eMGSRequestProgress {
	MGSRequestProgressNull = -1,
	MGSRequestProgressReady = 0,
	MGSRequestProgressSending,
	MGSRequestProgressWaitingForReply,
	MGSRequestProgressReceivingReply,
	MGSRequestProgressReplyReceived,
	MGSRequestProgressCompleteWithNoErrors,
	MGSRequestProgressCompleteWithErrors,
	MGSRequestProgressTerminatedByUser,
	MGSRequestProgressCannotConnect,
	MGSRequestProgressSuspended,
	MGSRequestProgressSuspendedSending,
	MGSRequestProgressSuspendedReceiving,
} eMGSRequestProgress;

@protocol MGSRequestProgressDelegate <NSObject>
@optional
- (void)requestProgressUpdated:(MGSRequestProgress *)sender;
@end

@interface MGSRequestProgress : NSObject <NSCopying> {
	id <MGSRequestProgressDelegate> _delegate;
	eMGSRequestProgress _value;
	NSString *_name;
	id _object;
	NSImage *_image;
	NSTimeInterval _duration;	// duration of current progress
	NSTimeInterval _totalDuration;   // total duration across multiple progress objects
	NSTimeInterval _remainingTime;
	NSString *_remainingTimeString;
	NSDate *_totalStartTime;
	NSDate *_startTime;
	NSTimer *_durationTimer;
	NSString *_durationString;
	double _transferRate;
	NSString *_transferRateString;
	double _percentageComplete;
	BOOL _detailVisible;
	unsigned long long _requestSizeTransferred;
	unsigned long long _requestSizeTotal;
	NSString *_requestSizeTotalString;
	NSString *_requestSizeTransferredString;
	NSString *_progressString;
	NSString *_overviewString;
	NSString *_resultString;
	double _maxProgress;
	double _minProgress;
	
	NSString *_waitString;
	NSString *_transferInitString;
	NSString *_nameCompleteString;
	BOOL _complete;
	int _waitCount;
}

@property id <MGSRequestProgressDelegate> delegate;
@property (copy) NSString *name;
@property (assign) NSImage *image;
@property eMGSRequestProgress value;
@property id object;
@property NSTimeInterval duration;
@property NSTimeInterval totalDuration;
@property NSTimeInterval remainingTime;
@property (readonly) double transferRate;
@property (readonly) NSString *transferRateString;
@property double percentageComplete;
@property BOOL detailVisible;
@property unsigned long long requestSizeTransferred;
@property (readonly) NSString *requestSizeTransferredString;
@property unsigned long long requestSizeTotal;
@property (readonly) NSString *requestSizeTotalString;
@property (readonly) NSString *progressString;
@property (copy) NSString *overviewString;
@property (copy) NSString *resultString;
@property double maxProgress;
@property double minProgress;
@property (getter=isComplete) BOOL complete;
@property (readonly) NSString *durationString;
@property (readonly) NSString *remainingTimeString;

+ (id)progressForStatus:(eMGSRequestStatus)status;
- (void)setValue:(eMGSRequestProgress)value object:(id)object;
+ (eMGSRequestProgress) progressValueForStatus:(eMGSRequestStatus)status;
- (void)setValueFromStatus:(eMGSRequestStatus)status;
- (void)startDurationTimer;
- (void)restartDurationTimer:(MGSRequestProgress *)progress;
- (void)stopDurationTimer;
- (void)durationTimerExpired:(NSTimer*)theTimer;
- (void)updateProgressString;
- (void)updateProgressStringAsDate;
- (void)initialize;

@end
