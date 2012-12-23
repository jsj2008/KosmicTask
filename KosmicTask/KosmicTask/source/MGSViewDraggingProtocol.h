//
//  MGSViewDraggingProtocol.h
//  KosmicTask
//
//  Created by Jonathan on 18/12/2012.
//
//

#ifndef KosmicTask_MGSViewDraggingProtocol_h
#define KosmicTask_MGSViewDraggingProtocol_h


#endif

@protocol MGSViewDraggingProtocol
- (NSDragOperation)draggingEntered:(id < NSDraggingInfo >)sender object:(id)object;
- (NSDragOperation)draggingUpdated:(id < NSDraggingInfo >)sender object:(id)object;
- (void)draggingExited:(id < NSDraggingInfo >)sender object:(id)object;
- (BOOL)prepareForDragOperation:(id < NSDraggingInfo >)sender object:(id)object;
- (BOOL)performDragOperation:(id < NSDraggingInfo >)sender object:(id)object;
- (void)concludeDragOperation:(id < NSDraggingInfo >)sender object:(id)object;
- (void)draggingEnded:(id < NSDraggingInfo >)sender object:(id)object;
@end
