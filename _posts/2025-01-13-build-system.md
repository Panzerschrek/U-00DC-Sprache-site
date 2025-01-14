---
title: Ü build system
---

## Ü build system

### Motivation

Any modern language should have some kind of software for building of projects written in it.
Having only compiler isn't enough, since it's too tedious to execute it manually or even write a shell script for doing this.
So, some kind of build system is necessary to simplify building programs consisting of many source files and build targets and with possible dependencies.
Also it's nice if such tool can do package managing.

Well-known examples of build systems are *cargo* for Rust, *CMake* for C++, *Maven*/*Gradle* for Java.
Some languages have some kind of build system integrated within their compiler, like in case of *Go* or *Swift*.

Also it's important to have only single build system for a language.
This ensures that everyone uses the same format for libraries building and thus makes using thirdparty libraries as easy as it can be.
A bad example is the zoo of C++ build systems.
There are *CMake*, *MSBuild*, *GNU Make* and a lot of other not so popular build systems and several semi-working package managers, like *Conan*.

Ü is no exception and should have its own build system.
Eventually I decided to write one.


### Chosen approach

Many build systems use a language for projects description which is distinct from target language.
*CMake* and *GNU Make* are de-facto separate languages (wit very poor design), *MSBuild* uses XML for projects description (but it's usually modified via Visual Studio GUI, not by hand), *Cargo* uses *toml* format.
Such approach seems to create some friction - one need to learn a separate language to be able to write build files.
I didn't want to create such friction and thus I selected Ü language itself for writing project files.

A build script for a package is just an Ü source file, which should contain a function with well-known name, which returns a structure with description for given project - in format known for Ü build system.
This build script is compiled by the build system into a shared library and this function is executed to obtain project information.
Later the build system executes necessary steps to execute the build.

It's important to mention, that a user-defined build script doesn't execute any build commands directly, but only forms project description.
This seems to be somewhat limited, but actually this approach gives more flexibility and gives the Ü build system possibility to perform things like incremental building and re-using of common dependencies.
Declarative description is also usually shorter compared to an approach with direct commands execution.

But why one still need Turing-completeness of a language like Ü for project description files?
For simple projects it isn't necessary, it may be enough to just list build targets, source files, dependencies.
But generally this list may depend on some conditions, like target system, build configuration, environment, etc.
So, using a Turing-complete language for such purposes makes sense.

The approach selected has one significant disadvantage.
There isn't enough isolation between user's code in build scripts and the build system code - all user-created build scripts are executed within build system process.
A poorly-written build script may trigger process termination by using `halt` or may behave even worse by messing with unsafe code.
But I think it's not that bad and some sort of isolation may be introduced in future.


### General concepts overview

The main logical unit of a project is a build target.
It may be executable, library, native library or object file.
A build target has list of source files, dependencies and some additional properties.

Build targets may depend on each other (but obviously without dependency loops).
There are private and public dependencies.
A dependency is needed to be public if its declarations are used in public interface of current build target.
Otherwise it should be make private.

A build target may have zero or more public include directories.
Files within these directories are considered to be public headers and they may be imported by current build target and build targets which depend on it.
Such imports should start with name equal to the build target name.

There is proper isolation of build target files from each other.
No two build targets can share common source or header files.
Imports are limited to the source directory of the build target, its public include directories and public include directories of its dependencies.


### Packages

The root package may depend on other packages and they can depend on other packages too.
There are two kinds of packages - sub-packages (located within a directory of another packages) and global versioned packages.

Build targets of a package may depend on build targets of dependent packages - for such dependencies package name should be specified.

For now there is no centralized packages repository.
But it can be created, global versioned packages exist exactly to be stored within such repository.
For now such repository may be emulated by just collecting a bunch of packages within a directory and specifying the path to this directory via corresponding command-line option.


### Code generation

There are custom build steps, which allow to run an external executable to produce a file (or several files) based on other files.
Such custom build steps may be used for code generation - source files, private header files, public header files.

It's possible to build a tool for code generation, there is a special mechanism for doing this.
A package dependency may be specified as host package dependency.
Such package will be built for host system and its executables may be used in custom build steps.


### Dependencies isolation

Ü build system performs some tricks to avoid conflicts of symbols from different build targets, including different versions of the same build target.

All functions of a build target, which are not declared in public header files, are internalized (made private).
Doing so allows defining in different build targets internal functions with identical names without possible name conflicts in linking.
This also helps in later link-time optimization, since such functions may be inlined.

All functions from a private dependency are made private.
This allows using in two different build targets libraries with possible conflicting public functions or even two versions of the same build target (from different versions of a global versioned package).
This shouldn't lead to name conflicts during linking caused by such libraries.

In cases where a build target obtains transitive dependencies on different versions of a build target from a global versioned package, versions unification may be performed to avoid such conflicting dependencies.
This process changes versions of dependencies in some build targets until no conflicts are left.

For now there is a strange behavior caused by the dependencies isolation approach described above.
If a build target is used privately by more than one other build targets and these build targets are linked into an executable or shared library, global mutable variables defined in the first mentioned build target may be duplicated. So, it's recommended to avoid using global mutable variables if such behavior isn't desired (it's a general advice) or (if using global mutable variables is necessary) to use such build target only as public dependency.


### Results and conclusion

All functionality described above was implemented in a couple of months.
It required some extra changes in Ü compiler, mostly involving imports managing and symbols isolation.

Many tests (more than 150) were written, they test all features and possible errors.
The Ü build system is now used for building of the Compiler2 (Compiler1 built with Compiler1), which includes non-trivial code generation.

The build system in current state should be usable, its API is stable enough (or almost stable), no breaking changes should be done later.
There are of course some small internal improvements which may be done later and a couple of fixes which should be done sooner or later, but they doesn't affect overall usability.

Generally I hope this build system will become the standard of Ü code building and no project will be built without its usage.

The next big step is to introduce a centralized packages repository.
Global packages logic is already implemented, it requires only creating such repository (which isn't an easy task) and implementing packages downloading by the build system.

For additional information see [documentation](https://panzerschrek.github.io/U-00DC-Sprache-site/docs/en/build_system.html).
