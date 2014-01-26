libcypto dynamic library is deprecatedas its API is deemed unstable.

Hence we link a static linstance of libcrypto.a obtained from macports and installed in /opt/local/library.
The include folder is copied from /opt/local/include.
Note that we could load the library directly from /opt/local/library.

To update /opt/local/library/libcrypto we can simply invoke:
sudo port selfupdate

Note that libcrypto has dependency on libz. Hence -lz is required in other linker flags.
