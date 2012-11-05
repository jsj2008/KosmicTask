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
#define MGS_INSTANCE_TRACKER_ALLOCATE MLogInfo(@"ALLOC: %@ activeInstances: %u", [self className], ++_MGSInstanceTracker)
#define MGS_INSTANCE_TRACKER_DEALLOCATE MLogInfo(@"DEALLOC: %@ activeInstances: %u", [self className], --_MGSInstanceTracker)

#else

#define MGS_INSTANCE_TRACKER_DEFINE
#define MGS_INSTANCE_TRACKER_ALLOCATE
#define MGS_INSTANCE_TRACKER_DEALLOCATE

#endif

#ifdef MGS_LOG_FINALIZE
#define MGS_INSTANCE_TRACKER_FINALIZE MLogInfo(@"FINALIZED: %@", [self className])
#else
#define MGS_INSTANCE_TRACKER_FINALIZE 
#endif
