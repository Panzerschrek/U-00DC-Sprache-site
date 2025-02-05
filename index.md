### About

Ü is a statically-typed compiled programming language.

The main goal of the language is a safety, but not with cost of bad performance and/or verbosity.

Read [overview](/overview.md) for more information.


### Language Development

Ü is an open-source software, distributed under the terms of BSD-3 license.
Anyone can participate in its development.

Ü compiler is based on LLVM library.

There are two compilers of Ü - Compiler0, written in C++ and Compiler1 - written (mostly) in Ü.
Besides the compiler another helpful components exist.


### Documentation

Documentation is available here: [english](https://panzerschrek.github.io/U-00DC-Sprache-site/docs/en/contents.html), [russian](https://panzerschrek.github.io/U-00DC-Sprache-site/docs/ru/contents.html).

The language itself is relatively good described.
Various components like compiler and standard library are described only briefly.

There are also some basic usage examples of different language features, available [here](https://github.com/Panzerschrek/U-00DC-Sprache/tree/master/source/examples).


### Development readiness

Ü as language is already pretty developed.
It contains most features required for effective coding.

The compiler is relatively stable and fast and may be used without problems.
It can even compile itself (Compiler1 version, obviously).

Ü has its own standard library with basic routines and containers (vector, optional, variant, etc.).
Also it contains basic functions for filesystem interaction.
Time-related functionality, networking or other system-specific functions aren't implemented yet.

Ü has its own build system.
It simplifies building Ü programs consisting of many source files, libraries, executables, etc.
Package management is supported, but for now there is no centralized packages repository.

Ü includes also a language server, that helps a lot during development.
It can be used with any IDE, that supports the Language Server Protocol.

Ü project includes syntax highlighting rules for some text editors/IDEs.
It's not so hard to write your own syntax highlighting file, if there is no such file for your IDE/text editor yet.

There is also a converter of C headers, that may help in creation of C bindings.
It's especially helpful until Ü has no big ecosystem of native (written in Ü) libraries.


### Links

[Source code](https://github.com/Panzerschrek/U-00DC-Sprache).
Contributions are welcome!

[Blog](/blog.md)

[Web Demo](/web_demo.md)

[ProgrammingLanguages Discord channel](https://discord.com/channels/530598289813536771/1227680274045997176)


### Compiler downloads

[GNU/Linux build](https://panzerschrek.github.io/U-00DC-Sprache-site/compiler_gnu_linux.zip)

[Windows build](https://panzerschrek.github.io/U-00DC-Sprache-site/compiler_windows.zip)

You can build Ü compiler and tools for other systems from the source code.
See more information in the project repository.


### Authors

Copyright © 2016-2025 "Panzerschrek".
