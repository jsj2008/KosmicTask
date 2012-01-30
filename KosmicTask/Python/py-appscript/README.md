Notes on how to build py-appscript for distribution with KosmicTask.

Run easy install and copy the egg into the local install folder

	sudo easy_install appscript
	Password:
	Searching for appscript
	Reading http://pypi.python.org/simple/appscript/
	Reading http://appscript.sourceforge.net
	Best match: appscript 1.0.0
	Downloading http://pypi.python.org/packages/source/a/appscript/appscript-1.0.0.tar.gz#md5=6619b637037ea0f391f45870c13ae38a
	Processing appscript-1.0.0.tar.gz
	Running appscript-1.0.0/setup.py -q bdist_egg --dist-dir /tmp/easy_install-psKMyL/appscript-1.0.0/egg-dist-tmp-B5KJSh
	zip_safe flag not set; analyzing archive contents...
	Adding appscript 1.0.0 to easy-install.pth file

	Installed /Library/Python/2.6/site-packages/appscript-1.0.0-py2.6-macosx-10.6-universal.egg
	Processing dependencies for appscript
	Finished processing dependencies for appscript

	sudo cp /Library/Python/2.6/site-packages/appscript-1.0.0-py2.6-macosx-10.6-universal.egg /Users/Jonathan/Documents/Computing/source/KosmicTask/KosmicTask/Python/py-appscript/install 
