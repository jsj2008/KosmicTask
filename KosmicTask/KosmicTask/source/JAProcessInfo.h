#import <Cocoa/Cocoa.h> 

@interface JAProcessInfo : NSObject {
	
@private
    size_t numberOfProcesses;
    NSMutableArray *processList;
}
- (id) init;
- (size_t)numberOfProcesses;
- (void)obtainFreshProcessList;
- (BOOL)findProcessWithName:(NSString *)procNameToSearch;
- (NSArray *)descendentsOfPID:(int)parentPID;

@end
