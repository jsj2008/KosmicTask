#PyYAML

[PyYAML](http://pyyaml.org/wiki/PyYAML) is a YAML parser and emitter for the Python programming language.

Both pure-Python and fast LibYAML-based parsers and emitters. We don't want the LibYAML bindings because we don't want to have to install LibYAML to the system library.

To build and install:

	python setup.py --without-libyaml install

The PyYAML folder contains the current package.

Without sudo this will try and fail to install to the system library folder. However, the local build folder will contain a yaml folder. This is copied to ./yaml.

The ./yaml folder is copied to the Python language plugin bundle.



