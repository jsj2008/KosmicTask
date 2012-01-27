#libYAML

KosmicTask does not link to libYaml directly but the library is used by YamlKit and others.

They generally retrieve the library from the system library path and bundle it as required.

The system version can be updated by running configure and make on the required package.