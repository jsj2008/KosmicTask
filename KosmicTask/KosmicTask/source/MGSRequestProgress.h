//
//  MGSRequestProgress.h
//  Mother
//
//  Created by Jonathan on 01/02/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "MGSNetRequest.h"

enum _eMGSRequestProgress {
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
};
typedef NSInteger eMGSRequestProgress;

@protocol MGSRequestProgressDelegate <NSObject>
@optional
- (void)requestProgressUpdated:(MGSRequestProgress *)sender;
@end

@interface MGSRequestProgress : NSObject <NSCopying> {
	__weak id <MGSRequestProgressDelegate> _delegate;
	eMGSRequestProgress _value;
	NSString *_name;
	id __unsafe_unretained _object;
	NSImage *_image;
	NSTimeInterval _duration;	// duration of current progress
	NSTimeInterval _totalDuration;   // total duration across multiple progress objects
	NSTimeInterval _remainingTime;
	NSString *__weak _remainingTimeString;
	NSDate *_totalStartTime;
	NSDate *_startTime;
	NSTimer *_durationTimer;
	NSString *__weak _durationString;
	double _transferRate;
	NSString *__weak _transferRateString;
	double _percentageComplete;
	BOOL _detailVisible;
	unsigned long long _requestSizeTransferred;
	unsigned long long _requestSizeTotal;
	NSString *__weak _requestSizeTotalString;
	NSString *__weak _requestSizeTransferredString;
	NSString *__weak _progressString;
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

@property (weak) id <MGSRequestProgressDelegate> delegate;
@property (copy) NSString *name;
@property (strong) NSImage *image;
@property eMGSRequestProgress value;
@property (unsafe_unretained) id object;
@property NSTimeInterval duration;
@property NSTimeInterval totalDuration;
@property NSTimeInterval remainingTime;
@property (readonly) double transferRate;
@property (weak, readonly) NSString *transferRateString;
@property double percentageComplete;
@property BOOL detailVisible;
@property unsigned long long requestSizeTransferred;
@property (weak, readonly) NSString *requestSizeTransferredString;
@property unsigned long long requestSizeTotal;
@property (weak, readonly) NSString *requestSizeTotalString;
@property (weak, readonly) NSString *progressString;
@property (copy) NSString *overviewString;
@property (copy) NSString *resultString;
@property double maxProgress;
@property double minProgress;
@property (getter=isComplete) BOOL complete;
@property (weak, readonly) NSString *durationString;
@property (weak, readonly) NSString *remainingTimeString;

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
