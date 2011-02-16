/*
 *  MacRuby_main.m
 *  KosmicTaskHost
 *
 *  Created by Jonathan on 28/04/2010.
 *  Copyright 2010 mugginsoft.com. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>
#import <MacRuby/MacRuby.h>

int main(int argc, const char *argv[])
{
	// MacRuby main
	return macruby_main("macruby_main.rb", argc, argv);
	
}
