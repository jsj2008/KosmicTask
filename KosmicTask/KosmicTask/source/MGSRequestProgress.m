//
//  MGSRequestProgress.m
//  Mother
//
//  Created by Jonathan on 01/02/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
// note that MGSNetRequest defines a request status
// but that is fine grained and does not report error
// conditions, merely the status of the request exchange with the server
//
#import "MGSRequestProgress.h"
#import "MGSImageManager.h"
#import "MGSError.h"
#import "NSString_Mugginsoft.h"
#import "MGSTimeIntervalTransformer.h"
#import "MLog.h"

static MGSTimeIntervalTransformer *timeIntervalTransformer;

@implementation MGSRequestProgress

@synthesize delegate = _delegate;
@synthesize name = _name;		// bound to
@synthesize image = _image;		// bound to
@synthesize value = _value;
@synthesize object = _object;
@synthesize duration = _duration;
@synthesize totalDuration = _totalDuration;
@synthesize transferRate = _transferRate;
@synthesize percentageComplete = _percentageComplete;
@synthesize remainingTime = _remainingTime;
@synthesize detailVisible = _detailVisible;
@synthesize requestSizeTransferred = _requestSizeTransferred;
@synthesize requestSizeTotal = _requestSizeTotal;
@synthesize requestSizeTotalString = _requestSizeTotalString;
@synthesize transferRateString = _transferRateString;
@synthesize requestSizeTransferredString = _requestSizeTransferredString;
@synthesize progressString = _progressString;
@synthesize overviewString = _overviewString;
@synthesize resultString = _resultString;
@synthesize maxProgress = _maxProgress;
@synthesize minProgress = _minProgress;
@synthesize complete = _complete;
@synthesize durationString = _durationString;
@synthesize remainingTimeString = _remainingTimeString;

#pragma mark -
#pragma mark Class methods
/*
 
 overviewString dependent keys
 
 */
+ (NSSet *)keyPathsForValuesAffectingOverviewString
{
    return [NSSet setWithObjects:@"resultString", nil];
}

/*
 
 get progress value for status
 
 */
+ (eMGSRequestProgress)progressValueForStatus:(eMGSRequestStatus)status
{
	eMGSRequestProgress progress;
	
	switch (status) {
		case kMGSStatusSendingMessage:
			progress = MGSRequestProgressSending;
			break;
			
		case kMGSStatusReadingMessageHeaderPrefix:
			progress = MGSRequestProgressWaitingForReply;
			break;
			
		case kMGSStatusReadingMessageBody:
			progress = MGSRequestProgressReceivingReply;
			break;
			
		case kMGSStatusMessageReceived:	
			progress = MGSRequestProgressReplyReceived;
			// perhaps do not need to progress this as a success or fail
			// message must soon follow?
			//return nil;	
			break;
			
		case kMGSStatusExceptionOnConnecting:
		case kMGSStatusCannotConnect:
			progress = MGSRequestProgressCannotConnect;
			break;
			
            // we don't need to progress any other values
		default:
			progress = MGSRequestProgressNull;
			break;
	}
	
	return progress;
}

/*
 
 progress for status

 return a progress object representing the request status.
 returns nil if no appropriate progress found
 
 */
+ (id)progressForStatus:(eMGSRequestStatus)status
{
	eMGSRequestProgress progress = [self progressValueForStatus:status];
	if (progress == MGSRequestProgressNull) {
		return nil;
	}
	
	MGSRequestProgress *requestProgress = [[[self class] alloc] init];
	[requestProgress setValue:progress];
	
	return requestProgress;
}
/*
 
 initialise class
 
 */
+ (void)initialize
{
	if ( self == [MGSRequestProgress class] ) {
		timeIntervalTransformer = [[MGSTimeIntervalTransformer alloc] init];
		timeIntervalTransformer.resolution = MGSTimeSecond;
		timeIntervalTransformer.style = MGSTimeStyleTextual;
		timeIntervalTransformer.returnAttributedString = NO;
	}
}

#pragma mark -
#pragma mark Instance handling
/*
 
 init
 
 */
- (id)init
{
	if ((self = [super init])) {
		[self initialize];
	}
	return self;
}

/*
 
 initialise instance
 
 */
- (void)initialize
{
	self.duration = [MGSTimeIntervalTransformer nullTimeInterval];
	self.totalDuration = [MGSTimeIntervalTransformer nullTimeInterval];
	self.remainingTime = [MGSTimeIntervalTransformer nullTimeInterval];
	_durationTimer = nil;
	_transferRate = 0;
	self.percentageComplete = 0;
	self.detailVisible = NO;
	self.requestSizeTransferred = 0;
	self.requestSizeTotal = 0;
	_requestSizeTotalString = @"";
	_transferRateString = @"";
	_requestSizeTransferredString = @"";
	self.minProgress = 0;
	self.maxProgress = 0;
	_progressString = @"";
	_overviewString = nil;
	_resultString = nil;
	[self setValue:MGSRequestProgressReady];
	_nameCompleteString = nil;	
	_complete = NO;
	_waitCount = 0;
	
	_waitString = NSLocalizedString(@"Waiting for task", @"Request progress table waiting for request reponse");
	_transferInitString = NSLocalizedString(@"Initializing", @"Request progress table initialising transfer");

}

/*
 
 - description
 
 */
- (NSString *)description
{
    NSString *description = [NSString stringWithFormat:@"eMGSRequestProgress:%lu %@", (long)self.value, self.name];
    return description;
}

#pragma mark -
#pragma mark Accessors
/*
 
 set request size total
 
 */
- (void)setRequestSizeTotal:(unsigned long long)value
{
	_requestSizeTotal = value;
	[self willChangeValueForKey:@"requestSizeTotalString"];
	_requestSizeTotalString = [NSString mgs_stringFromFileSize:_requestSizeTotal];
	[self didChangeValueForKey:@"requestSizeTotalString"];
	
	[self updateProgressString];
}

/*
 
 set request size transferred
 
 */
- (void)setRequestSizeTransferred:(unsigned long long)value
{
	if (value < self.requestSizeTotal) {
		_requestSizeTransferred = value;
	} else {
		_requestSizeTransferred = self.requestSizeTotal;
	}
	
	// update size transferred string
	[self willChangeValueForKey:@"requestSizeTransferredString"];
	_requestSizeTransferredString = [NSString mgs_stringFromFileSize:_requestSizeTransferred];
	[self didChangeValueForKey:@"requestSizeTransferredString"];
	
	[self updateProgressString];
}

/*
 
 set overview string
 
 */
- (void)setOverviewString:(NSString *)newValue
{
	_overviewString = newValue;
}

/*
 
 overview string
 
 */
- (NSString *)overviewString
{
	if (!_resultString) {
		return _overviewString;
	} else {
		return [_overviewString stringByAppendingFormat:@": %@", _resultString];
	}
}
/*
 
 set result string
 
 */
- (void)setResultString:(NSString *)newValue
{
	_resultString = newValue;
}

/*
 
 set value
 
 */
- (void)setValue:(eMGSRequestProgress)value 
{
#ifdef MGS_DEBUG_PROGRESS
    MLogInfo(@"%lx %@ %@ eMGSRequestProgress: %lu", self, [self className], NSStringFromSelector(_cmd), (long)value);
#endif
    
	[self setValue:value object:nil];
}

/*
 
 set value from status
 
 */
- (void)setValueFromStatus:(eMGSRequestStatus)status
{
#ifdef MGS_DEBUG_PROGRESS
    MLogInfo(@"%lx %@ %@ eMGSRequestStatus: %lu", self, [self className], NSStringFromSelector(_cmd), (long)status);
#endif
    
	eMGSRequestProgress progress = [MGSRequestProgress progressValueForStatus:status];
    
    // a null indicates that there is not a distinct progress value for the status
	if (progress == MGSRequestProgressNull) {
        
#ifdef MGS_DEBUG_PROGRESS
    MLogInfo(@"%lx %@ %@ progress == MGSRequestProgressNull", self, [self className], NSStringFromSelector(_cmd));
#endif
		return;
	}
	
	[self setValue:progress object:nil];
}

/*
 
 set progress value and object
 
 */
- (void)setValue:(eMGSRequestProgress)value object:(id)object
{

	// note that raising notifications here causes entries to be repeated
	// in the progress table
	//[self willChangeValueForKey:@"value"];
	_value = value;
	//[self didChangeValueForKey:@"value"];

	self.object = object;
	NSString *text = nil, *message = nil;
	NSImage *image = nil;
	BOOL progressDate = NO;
	
	if ([object isKindOfClass:[NSString class]]) {
		message = object;
	} else if ([object isKindOfClass:[MGSError class]]) {
		message = [(MGSError *)object stringValuePreview];
	} else {
		message = nil;
	}
	
	[self willChangeValueForKey:@"progressString"];
	
	switch (_value) {
		case MGSRequestProgressReady:
			text = NSLocalizedString(@"Ready", @"output request: action ready");
			_nameCompleteString = NSLocalizedString(@"Started", @"output request: action started");
			image = [[[MGSImageManager sharedManager] info] copy];
			break;

		case MGSRequestProgressSending:
			image = [[[MGSImageManager sharedManager] rightArrow] copy];
			text = NSLocalizedString(@"Sending", @"output request: sending action");
			_nameCompleteString = NSLocalizedString(@"Sent", @"output request: action data sent");
			self.maxProgress = 100;	
			_progressString = _transferInitString;
			break;
			
		case MGSRequestProgressWaitingForReply:
			image = [[[MGSImageManager sharedManager] clockFace] copy];
			text = NSLocalizedString(@"Running", @"output request: action running");
			_nameCompleteString = NSLocalizedString(@"Run", @"output request: action has run to completion");
			_progressString = _waitString;
			break;
			
		case MGSRequestProgressReceivingReply:
			image = [[[MGSImageManager sharedManager] leftArrow] copy];
			text = NSLocalizedString(@"Receiving", @"output request: receiving reply");
			_nameCompleteString = NSLocalizedString(@"Received", @"output request: action data received");
			self.maxProgress = 100;
			_progressString = _transferInitString;
			break;

		case MGSRequestProgressReplyReceived:
			image = [[[MGSImageManager sharedManager] box] copy];
			text = NSLocalizedString(@"Processing", @"output request: reply received, processing data");
			_nameCompleteString = NSLocalizedString(@"Processed", @"output request: action data processed");
			break;
			
		case MGSRequestProgressCompleteWithNoErrors:
			image = [[[MGSImageManager sharedManager] tick] copy];
			text = NSLocalizedString(@"Finished", @"output request: action complete");
			progressDate = YES;
			break;		

		case MGSRequestProgressCompleteWithErrors:
			image = [[[MGSImageManager sharedManager] alertTriangle] copy];
			text = NSLocalizedString(@"Error", @"output request: action error");
			_progressString = message;
			break;		
		
		case MGSRequestProgressCannotConnect:
			image = [[[MGSImageManager sharedManager] cross] copy];
			text = NSLocalizedString(@"Unavailable", @"output request: cannot connect");
			progressDate = YES;
			break;		
		
		case MGSRequestProgressTerminatedByUser:
			image = [[[MGSImageManager sharedManager] cross] copy];
			text = NSLocalizedString(@"Stopped", @"output request: terminated by user");
			progressDate = YES;
			break;		

		case MGSRequestProgressSuspended:
			image = [[[MGSImageManager sharedManager] clockFace] copy];
			text = NSLocalizedString(@"Paused", @"output request: paused");
			progressDate = YES;
			break;
		
		case MGSRequestProgressSuspendedSending:
			image = [[[MGSImageManager sharedManager] clockFace] copy];
			text = NSLocalizedString(@"Send Paused", @"output request: send paused");
			progressDate = YES;
			break;

		case MGSRequestProgressSuspendedReceiving:
			image = [[[MGSImageManager sharedManager] clockFace] copy];
			text = NSLocalizedString(@"Recv Paused", @"output request: receive paused");
			progressDate = YES;
			break;
			
		default:
			NSAssert(NO, @"invalid request progress value");
			return;
	}
	
	[self didChangeValueForKey:@"progressString"];
	
	self.name = text;
	self.image = image;
	self.overviewString = text;
	
	// set progress string to date
	if (progressDate) {
		[self updateProgressStringAsDate];
	}
	
}

/*
 
 set remaining time
 
 */
- (void)setRemainingTime:(NSTimeInterval)value
{
	_remainingTime = value;
	[self willChangeValueForKey:@"remainingTimeString"];
	_remainingTimeString = [timeIntervalTransformer transformedValue:[NSNumber numberWithDouble:_remainingTime]];
	[self didChangeValueForKey:@"remainingTimeString"];
}

#pragma mark -
#pragma mark Duration timer
/*
 
 start duration timer
 
 */
- (void)startDurationTimer
{
	_startTime = [NSDate date];
	_totalStartTime = _startTime;
	self.duration = 0;
	self.totalDuration = 0;
	_durationTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(durationTimerExpired:) userInfo:nil repeats:YES];
}

/*
 
 restart duration timer using progress
 
 */
- (void)restartDurationTimer:(MGSRequestProgress *)progress
{
	_startTime = [NSDate date];
	_totalStartTime = [NSDate dateWithTimeIntervalSinceNow: -progress.totalDuration];
	self.duration = 0;
	self.totalDuration = progress.totalDuration;
	self.requestSizeTransferred = progress.requestSizeTransferred;
	self.requestSizeTotal = progress.requestSizeTotal;
	self.remainingTime = progress.remainingTime;
	_durationTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(durationTimerExpired:) userInfo:nil repeats:YES];
	
	// fire now
	[_durationTimer fire];
}
/*
 
 stop duration timer
 
 */
- (void)stopDurationTimer
{
	if (_durationTimer) {
		[_durationTimer invalidate];
		[self durationTimerExpired:_durationTimer];
		_durationTimer = nil;
	}
}

/*
 
 timer expired
 
 */
- (void)durationTimerExpired:(NSTimer*)theTimer
{
	#pragma unused(theTimer)

	switch (self.value) {
			
		case MGSRequestProgressReady:
			self.duration = -1;
			return;
			break;
			
		case MGSRequestProgressSending:
		case MGSRequestProgressReceivingReply:
		case MGSRequestProgressWaitingForReply:
		case MGSRequestProgressSuspended:
		case MGSRequestProgressSuspendedSending:
		case MGSRequestProgressSuspendedReceiving:
		case MGSRequestProgressReplyReceived:
		case MGSRequestProgressCompleteWithNoErrors:
		case MGSRequestProgressCompleteWithErrors:
		case MGSRequestProgressCannotConnect:
		case MGSRequestProgressTerminatedByUser:
			break;
			
		default:
			NSAssert(NO, @"invalid request progress value");
	}
	
	// update duration
	self.totalDuration = -[_totalStartTime timeIntervalSinceNow];
	self.duration =  -[_startTime timeIntervalSinceNow];;
	
	// update transfer rate
	switch (self.value) {
			
		case MGSRequestProgressSending:
		case MGSRequestProgressReceivingReply:;

			[self willChangeValueForKey:@"transferRate"];
			if (self.totalDuration > 0) {
				_transferRate = ((double)_requestSizeTransferred) / self.totalDuration;
			} else {
				_transferRate = 0;
			}
			[self didChangeValueForKey:@"transferRate"];
			
			// update transfer rate string
			[self willChangeValueForKey:@"transferRateString"];
			_transferRateString = [NSString stringWithFormat:@"%@/s", [NSString mgs_stringFromFileSize:(unsigned long long)_transferRate]];
			[self didChangeValueForKey:@"transferRateString"];
			
			// update remaining time
			if (self.transferRate > 0) {
				self.remainingTime = (self.requestSizeTotal - self.requestSizeTransferred) /  self.transferRate;
			} else {
				self.remainingTime = [MGSTimeIntervalTransformer nullTimeInterval];
			}
			break;
			
		default:
			break;
	}
	
	[self updateProgressString];
}

/*
 
 set duration
 
 */
- (void)setDuration:(NSTimeInterval)value
{
	_duration = value;
}

#pragma mark -
#pragma mark Progress representation
/*
 
 update progress string
 
 */
- (void)updateProgressString
{
	const int maxWaitCount = 3;
	NSString *formatString = nil;
	
	[self willChangeValueForKey:@"progressString"];

	switch (self.value) {
		case MGSRequestProgressReady:
			break;
			
		case MGSRequestProgressSending:
		case MGSRequestProgressReceivingReply:
			_waitCount = 0;
			
			// update progress string
			if (self.transferRateString && _transferRate > 0) {
				formatString = NSLocalizedString(@"%@ of %@ at %@" , @"Request send/receive progress information format string eg: 1 MB of 100 MB at 1MB/s");
				_progressString = [NSString stringWithFormat:formatString, self.requestSizeTransferredString, self.requestSizeTotalString, self.transferRateString];
			} else {
				formatString = NSLocalizedString(@"%@ of %@" , @"Request send/receive progress information format string eg: 1 MB of 100 MB");
				_progressString = [NSString stringWithFormat:formatString, self.requestSizeTransferredString, self.requestSizeTotalString];
			}
			
			break;
			
		case MGSRequestProgressWaitingForReply:
			
			// show textually animated wait string
			_progressString = _waitString;
			if (_waitCount > maxWaitCount) {
				_waitCount = 1;
			}
			
			if (_waitCount > 0) {
				_progressString = [_progressString stringByAppendingString: [@"" stringByPaddingToLength:_waitCount withString:@"." startingAtIndex:0]];
			}
			
			_waitCount++;
			break;
		
		case MGSRequestProgressSuspendedSending:
			break;
			
		case MGSRequestProgressSuspendedReceiving:
			break;
			
		case MGSRequestProgressReplyReceived:
			break;
			
		case MGSRequestProgressCompleteWithNoErrors:
			break;		
			
		case MGSRequestProgressCompleteWithErrors:
			break;		
			
		case MGSRequestProgressCannotConnect:
			break;		
			
		case MGSRequestProgressTerminatedByUser:
			break;		
			
		case MGSRequestProgressSuspended:
			break;

		default:
			NSAssert(NO, @"invalid request progress value");
	}
	
	[self didChangeValueForKey:@"progressString"];

	// update
	if (_progressString) {
		if (self.remainingTimeString && ![self.remainingTimeString isEqualToString:[MGSTimeIntervalTransformer nullTimeString]]) {
			formatString = NSLocalizedString(@"%@: %@ (%@ remaining)" , @"Request progress overviewString format");
			self.overviewString = [NSString stringWithFormat: formatString, _name, _progressString, self.remainingTimeString];
		} else {
			formatString = NSLocalizedString(@"%@: %@" , @"Request progress overviewString format");
			self.overviewString = [NSString stringWithFormat: formatString, _name, _progressString];
		}
	} 
	
	// inform delegate
	if (_delegate && [_delegate respondsToSelector:@selector(requestProgressUpdated:)]) {
		[_delegate requestProgressUpdated:self];
	}
}

/*
 
 update progress string as date
 
 */
- (void)updateProgressStringAsDate
{
	[self willChangeValueForKey:@"progressString"];
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"HH:mm 'on' EEEE MMMM d"];
	_progressString = [dateFormatter stringFromDate:[NSDate date]];
	
	[self didChangeValueForKey:@"progressString"];
}

/*
 
 finalize progress string
 
 */
- (void)finalizeProgressString
{
	BOOL progressDate = NO;
	
	[self willChangeValueForKey:@"progressString"];
	
	switch (self.value) {
		case MGSRequestProgressReady:
			progressDate = YES;
			break;
			
		case MGSRequestProgressSending:
			break;
			
		case MGSRequestProgressReceivingReply:
			break;
			
		case MGSRequestProgressWaitingForReply:
			_progressString = NSLocalizedString(@"Complete", @"Request progress table waiting complete for request reponse");;
			break;
			
		case MGSRequestProgressReplyReceived:
			break;
			
		case MGSRequestProgressCompleteWithNoErrors:
			break;		
			
		case MGSRequestProgressCompleteWithErrors:
			break;		
			
		case MGSRequestProgressCannotConnect:
			break;		
			
		case MGSRequestProgressTerminatedByUser:
			break;		
			
		case MGSRequestProgressSuspended:
			break;

		case MGSRequestProgressSuspendedSending:
			break;

		case MGSRequestProgressSuspendedReceiving:
			break;

		default:
			NSAssert(NO, @"invalid request progress value");
	}
		
	[self didChangeValueForKey:@"progressString"];

	// set progress string to date
	if (progressDate) {
		[self updateProgressStringAsDate];
	}
	
}


/*
 
 set complete
 
 the progress has finished updating
 
*/
- (void)setComplete:(BOOL)value
{
	_complete = value;
	
	self.percentageComplete = 100;	// mark as 100% complete
	[self finalizeProgressString];
	
	// if name defined for completion then use it
	if (_nameCompleteString) {
		self.name = _nameCompleteString;
	}
	
	switch (self.value) {
		case MGSRequestProgressReady:
			break;
			
		case MGSRequestProgressSending:
			self.remainingTime = [MGSTimeIntervalTransformer nullTimeInterval];
			break;
			
		case MGSRequestProgressReceivingReply:
			self.remainingTime = [MGSTimeIntervalTransformer nullTimeInterval];
			break;
			
		case MGSRequestProgressWaitingForReply:
			break;
			
		case MGSRequestProgressReplyReceived:
			break;
			
		case MGSRequestProgressCompleteWithNoErrors:
			break;		
			
		case MGSRequestProgressCompleteWithErrors:
			break;		
			
		case MGSRequestProgressCannotConnect:
			break;		
			
		case MGSRequestProgressTerminatedByUser:
			break;		
			
		case MGSRequestProgressSuspended:
			break;

		case MGSRequestProgressSuspendedSending:
			break;

		case MGSRequestProgressSuspendedReceiving:
			break;

		default:
			NSAssert(NO, @"invalid request progress value");
	}
	
}

#pragma mark -
#pragma mark NSCopying protocol message
/*
 
 copy with zone
 
 */
- (id)copyWithZone:(NSZone *)zone
{
	// use of NSCopyObject is not recommended.
	// see Cocoa Design Patterns for more
	id copy = NSCopyObject(self, 0, zone);

	return copy; 
}
@end
