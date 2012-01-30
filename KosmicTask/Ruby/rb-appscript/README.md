
To install appscript, cd to the rb-appscript-0.6.1 directory and run:

	ruby extconf.rb
	make
	make install

This installs and builds the ae bundle and OS X 10.7.

The system installation path is:

	/Library/Ruby/Site/1.8

We copy the installed ae bundle and rb files to the local folder for installation into the Ruby language plug-in bundle.

It would be better if we could define the install directory on the make file command line rather than digging through the library folder.

	make install PREFIX=/Users/Jonathan/Documents/Computing/source/KosmicTask/KosmicTask/Ruby/rb-appscript/install/test

The above should override the prefix variable but for some reason it fails.

Note that the 10.6 version needs to target the 10.6 frameworks and link against them.
