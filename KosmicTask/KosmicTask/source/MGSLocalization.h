//
//  MGSLocalization.h
//  Mother
//
//  Created by Jonathan on 02/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*
 Localized strings are accessed as so
 format = NSLocalizedSt*ingFromTable(@"%d Mother available (%d hidden)", MGSStringTableMother, “Only 1 machine available to user”);
 (note that using the full macro name in this comment crashes genstrings!
 
 To generate the strings file(s) (named Mother.strings etc) use: */
// genstrings *[hmc] */*[hmc] */*/*[hmc]
 /*
 this will search down through three folders looking for NSLocalizedSt*ingFromTable
  and will extract the keys. values and commecnts into the strings file
 */

#define MGSStringTableMother @"Mother"

 
/*
 @interface MGSLocalization : NSObject {

}
@end
 */
