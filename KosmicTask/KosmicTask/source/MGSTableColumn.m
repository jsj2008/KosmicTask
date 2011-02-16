//
//  MGSTableColumn.m
//  Mother
//
//  Created by Jonathan on 19/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSTableColumn.h"
#import "iTableColumnHeaderCell.h"

@implementation MGSTableColumn
/*
 The Object Loading Process
 When you use the methods of NSNib or NSBundle to load and instantiate the objects in a nib file, Cocoa does the following:
 
 Cocoa loads the contents of the nib file into memory:
 The raw data for the nib object graph is loaded into memory but is not unarchived.
 Any custom image resources associated with the nib file are loaded and added to the Cocoa image cache; 
 see “About Image and Sound Resources.”
 Any custom sound resources associated with the nib file are loaded and added to the Cocoa sound cache; 
 see “About Image and Sound Resources.”
 It unarchives the nib object graph data.
 Standard Interface Builder objects (and custom subclasses of those objects) receive an initWithCoder: message.
 Standard objects are the objects you drag into a nib file from the Interface Builder palettes. 
 Even if you change the class of such an object, Interface Builder encodes the standard object 
 into the nib file and then tells the archiver to swap in your custom class when the object is unarchived.
 
 Custom subclasses of NSView receive an initWithFrame: message.
 This case applies only when you use a custom view object in Interface Builder. 
 When it encounters a custom view, Interface Builder encodes a special NSCustomView object into your nib file. 
 The custom view object includes the information it needs to build the real view subclass you specified. 
 At load time, the NSCustomView object sends an alloc and initWithFrame: message to the real view class and 
 then swaps the resulting view object in for itself. The net effect is that the real view object handles 
 subsequent interactions during the nib-loading process.
 
 Non-view objects in the archive receive an init message.
 It reestablishes all connections (actions, outlets, and bindings) between objects in the nib file. 
 This includes connections to File’s Owner and other proxy objects.
 It sends an awakeFromNib message to all objects that define the matching selector.
 It displays any windows whose “Visible at launch time” attribute was enabled in Interface Builder.
 During the reconnection process, the nib-loading code reconnects any outlets, actions, and bindings 
 you created in Interface Builder. When reestablishing outlet connections, Cocoa tries to do so using
 the object’s own methods first. For each outlet, Cocoa looks for a method of the form setOutletName:
 and calls it if such a method is present. If it cannot find such a method, Cocoa searches the object
 for an instance variable with the corresponding outlet name and tries to set the value directly. 
 If the instance variable cannot be found, no connection is created.
 
 For actions, Cocoa uses the source object’s setTarget: and setAction: methods to establish the connection
 to the target object. If the target object does not respond to the action method, no connection is created.
 A connection is still created if the target object is nil; however, this behavior 
 is used to support connections that occur through the responder chain. 
 Such connections have an action and a dynamic target object.
 
 Cocoa sends the awakeFromNib message to every object in the nib file that defines the corresponding selector. 
 This applies not only to the custom objects you added to the nib file but also to proxy objects such as File’s Owner. 
 The order in which Cocoa calls the awakeFromNib methods of objects in the nib file is not guaranteed, 
 although Cocoa tries to call the awakeFromNib method of File’s Owner last. 
 If you do need to perform some final initialization of your nib file objects, it is best to do so after your nib-loading calls return.
 */
- (id)initWithCoder:(NSCoder *)decoder
{
	id column = [super initWithCoder:decoder];
	id headerCell = [self headerCell];
	// I thought this would enable a fully functional subclassing of the table column header
	// but it does not seem to do so either!
	// this is legal if right is subclass of left + no more ivars
	headerCell->isa = [iTableColumnHeaderCell class];
	(void)headerCell;	// shut the compiler up
	return column;
}

@end
