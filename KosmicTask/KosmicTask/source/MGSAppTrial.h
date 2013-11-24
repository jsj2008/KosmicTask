/*
 *  MGSAppTrial.h
 *  KosmicTask
 *
 *  Created by Jonathan on 05/02/2010.
 *  Copyright 2010 mugginsoft.com. All rights reserved.
 *
 */

#define MGS_APP_TRIAL_DAYS 42

#define MGS_APP_TRIAL_VALID 1
#define MGS_APP_TRIAL_EXPIRED 0

static BOOL MGSAppTrialPeriodExpired(NSUInteger *trialDaysRemaining) __attribute__((__unused__));
static void MGSAppTrialCleanup() __attribute__((__unused__));
static BOOL MGSAppTrialCleanupDomain(NSString *domain);
static NSArray *MGSAppTrialDomains();
static NSString *MGSAppTrialDomain(NSDictionary **defaults);
static NSString *MGSAppTrialMakeDomain(NSDictionary **defaults);
static NSUInteger MGSRandomBelow(NSUInteger n);

static NSString *MGSTrialStartKey = @"data-t-event";
/*
 
 Application trial validation
 
 including this header causes the static code to be embedded into the module
 
 */

/*
 
 function MGSAppTrialPeriodExpired
 
 */
static BOOL MGSAppTrialPeriodExpired(NSUInteger *trialDaysRemaining)
{
	*trialDaysRemaining = 0;
	
	@try {
		// get trial domain
		NSDictionary *defaults = nil;
		MGSAppTrialDomain(&defaults);
		
		// look for trial start date key
		NSNumber *trialStartdateNumber = [defaults objectForKey:MGSTrialStartKey];
		if (![trialStartdateNumber isKindOfClass:[NSNumber class]]) {
			
			// clean and restart trial
			MGSAppTrialCleanup();
			MGSAppTrialDomain(&defaults);
			trialStartdateNumber = [defaults objectForKey:MGSTrialStartKey];
			
			if (![trialStartdateNumber isKindOfClass:[NSNumber class]]) {
				return NO;
			}
		}
		
		// get elapsed trial time
		NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
		NSTimeInterval startTime = [trialStartdateNumber doubleValue];
		NSTimeInterval elapsedTime = now - startTime;
		NSTimeInterval trialTime = (60 * 60 * 24) * MGS_APP_TRIAL_DAYS;
		
		// is elapsed time greater than trial time
		if (elapsedTime > trialTime) {
			return YES;
		}
		
		// trial days remaining
		*trialDaysRemaining = (int)ceil((trialTime - elapsedTime)/(60 * 60 * 24));
		
		// apply sanity
		if (*trialDaysRemaining > MGS_APP_TRIAL_DAYS) {
			*trialDaysRemaining = MGS_APP_TRIAL_DAYS;
		}
		if (*trialDaysRemaining < 1) {
			*trialDaysRemaining = 1;
		}
		
	} @catch (NSException *e) {
		NSLog(@"Trial exception: %@", e);
	}
	
	return NO;
}
/*
 
 function MGSAppTrialDomain
 
 */
static NSString *MGSAppTrialDomain(NSDictionary **defaults)
{
	NSDictionary *dict = nil;
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

	*defaults = nil;
	
	// look for existing trial domain from array
	for (NSString *domain in MGSAppTrialDomains()) {
		
		// load persistent domain
		dict = [userDefaults persistentDomainForName:domain];
		if (dict) {
			*defaults = dict; 
			return domain;
		}
	}
	
	// make new trial domain
	return MGSAppTrialMakeDomain(defaults);
}
/*
 
 function MGSAppTrialMakeDomain
 
 */
static NSString *MGSAppTrialMakeDomain(NSDictionary **defaults)
{
	NSString *domain = @"com.mugginsoft.task-0";
	
	@try {
		// get domain list
		NSArray *domains = MGSAppTrialDomains();
		
		// get random index
		NSUInteger idx = MGSRandomBelow([domains count]);
		
		//get domain
		domain = [domains objectAtIndex:idx];
	} @catch (NSException *e) {
		NSLog(@"Trial domain exception: %@", e);
	}
	
	// make persistent domain
	NSNumber *dateNumber = [NSNumber numberWithDouble:[NSDate timeIntervalSinceReferenceDate]];
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:dateNumber, MGSTrialStartKey, nil];
	[[NSUserDefaults standardUserDefaults] setPersistentDomain:dict forName:domain];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	*defaults = dict;
	return domain;
}
/*

function MGSAppTrialDomains

*/
static NSArray *MGSAppTrialDomains()
{
	NSString *fmt = @"%@%@%@";
	
	// note that some are hidden files and some are not
	NSArray *trialDomains = [NSArray arrayWithObjects:			
			[NSString stringWithFormat:fmt, @".com.", @"18776162715", @".task"],
			[NSString stringWithFormat:fmt, @".org.", @"adfsgdrtye123.", @"task.6"],
			[NSString stringWithFormat:fmt, @".org.", @"w55565_08.", @"updater-1"],
			[NSString stringWithFormat:fmt, @".net.", @"_jkui_890_.", @"net.task"],
			[NSString stringWithFormat:fmt, @".net.", @"_0SSFGHF_11.", @"0"],
			[NSString stringWithFormat:fmt, @".com.", @"156_sdd_133.", @"limits-0"],
			[NSString stringWithFormat:fmt, @".com.", @"jj_00_asd1.", @"status.read"],
			[NSString stringWithFormat:fmt, @".com.", @"178_sdfg_890.", @"status.2"],
			[NSString stringWithFormat:fmt, @".com.", @"as_as1_new.", @"task-19"],
			[NSString stringWithFormat:fmt, @".org.", @"122_asd_dfg.", @"ftp"],
			nil];
	
	return trialDomains;
}
/*
 
 function MGSRandomBelow
 
http://stackoverflow.com/questions/791232/canonical-way-to-randomize-an-nsarray-in-objective-c

*/
static NSUInteger MGSRandomBelow(NSUInteger n) {
    NSUInteger m = 1;
	
	srandom((unsigned int)time(NULL));
	
    do {
        m <<= 1;
    } while(m < n);
	
    NSUInteger ret;
	
    do {
        ret = random() % m;
    } while(ret >= n);
	
    return ret;
}

/*
 
 function MGSAppTrialCleanup
 
 */
static void MGSAppTrialCleanup()
{
	// look for existing trial domain from array
	for (NSString *domain in MGSAppTrialDomains()) {
		
		// cleanup domain
		MGSAppTrialCleanupDomain(domain);
	}
}

/*
 
 function MGSAppTrialCleanup
 
 */
static BOOL MGSAppTrialCleanupDomain(NSString *domain)
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	// load persistent domain
	NSDictionary *dict = [userDefaults persistentDomainForName:domain];
	if (!dict) {
		return NO;
	}
	
	// delete domain if it contains only our key
	if ([dict count] == 1 && [dict objectForKey:MGSTrialStartKey]) {
		[userDefaults removePersistentDomainForName:domain];
		[userDefaults synchronize];
	}
	
	return NO;
}

