#import <Cocoa/Cocoa.h> 

@interface JAProcessInfo : NSObject {
	
@private
    int numberOfProcesses;
    NSMutableArray *processList;
}
- (id) init;
- (int)numberOfProcesses;
- (void)obtainFreshProcessList;
- (BOOL)findProcessWithName:(NSString *)procNameToSearch;
- (NSArray *)descendentsOfPID:(int)parentPID;

@end
