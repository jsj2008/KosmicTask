Lua yaml was obtained from http://yaml.luaforge.net/

Note that the makefile is poor and won't correctly build the yaml.so.
I have patched it up.

Note that the notes at the above url on how to use the package are quite wrong. The shared object must be loaded as follows. No Path searching takes place.

path = "/full/path/to/yaml.so"
f = assert(package.loadlib(path, "luaopen_yaml"))
f()

The above can be placed in a file called yaml.lua and that can be
loaded using require("yaml"). This can be place on LUA_PATH.

see package.loadfile info here
http://www.lua.org/manual/5.1/manual.html


