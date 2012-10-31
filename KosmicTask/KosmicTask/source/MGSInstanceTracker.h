//
//  MGSInstanceTracker.h
//  KosmicTask
//
//  Created by Jonathan on 31/10/2012.
//
//

#ifndef KosmicTask_MGSInstanceTracker_h
#define KosmicTask_MGSInstanceTracker_h
#endif

#ifdef MGS_INSTANCE_TRACKER

#define MGS_INSTANCE_TRACKER_DEFINE static NSInteger _MGSInstanceTracker = 0
#define MGS_INSTANCE_TRACKER_ALLOCATE MLogDebug(@"ALLOC: %@ activeInstances: %u", [self className], ++_MGSInstanceTracker)
#define MGS_INSTANCE_TRACKER_DEALLOCATE MLogDebug(@"DEALLOC: %@ activeInstances: %u", [self className], --_MGSInstanceTracker)

#else

#define MGS_INSTANCE_TRACKER_DEFINE
#define MGS_INSTANCE_TRACKER_ALLOCATE
#define MGS_INSTANCE_TRACKER_DEALLOCATE

#endif


