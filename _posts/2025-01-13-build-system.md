---
title: Ü build system
---

## Ü build system

### Motivation

Any modern language should have some kind of software for building of projects written in it.
Having only compiler isn't enough, since it's too tedious to execute it manually or even write a shell script for doing this.
So, some kind of build system is necessary to simplify building programs consisting of many source files and build targets and with possible dependencies.

Examples of build systems are *cargo* for Rust, *CMake* for C++, *Maven*/*Gradle* for Java.
Some languages have some kind of build system integrated within their compiler, like in case of *Go* or *Swift*.

Also it's important to have only single build system for a language.
This ensures that everyone uses same format for libraries building and thus makes using thirdparty libraries as easy as it can be.
A bad example is the zoo of C++ build systems.
There are *CMake*, *MSBuild*, *GNU Make* and a lot of other not so popular build systems and several semi-working package managers, like *Conan*.


### Selected approach

Many build systems use a language for projects description which is distinct from target language.
*CMake* and *GNU Make* are de-facto separate languages, *MSBuild* exes XML for projects description (but it's usually modified via Visual Studio GUI, not by hand), *Cargo* uses *toml* format.
Such approach seems to create some friction - one need to learn a separate language to describe a project.
I didn't want to create such friction and thus I selected Ü language itself for writing project files.

A build script for a package is just a Ü source file, which should contain a function with well-known name, which returns project description structure - in format known for Ü build system.
This build script is compiled into a shared library and this function is executed to obtain project information.
Later Ü build system executes necessary steps to execute the build.

It's important to mention, that a user-defined build script doesn't execute any build commands directly, but only forms project description.
This seems to be somewhat limited, but actually this approach gives more flexibility and gives the Ü build system possibility to perform things like incremental building and re-using of common dependencies.
Declarative description is also usually shorter compared to approach with direct commands execution.

But why one still need Turing-completeness of a language like Ü for project description files?
For simple projects it isn't necessary, it may be enough to just list build targets, source files, dependencies.
But generally this list may depend on some conditions, like target system, build configuration, environment, etc.
So, using a Turing-complete language for such purposes makes sense.


### General concepts overview

A logical unit of a project is a build target.
It may be executable, library, native library or object file.
A build target has list of source files, dependencies and some additional properties.

Build targets may depend on each other (but without dependency loops).
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
For now such repository may be emulated by just collecting a bunch of packages within a directory and specifying path to this directory via corresponding command-line option.


### Advanced features

There are custom build steps, which allow to run an external executable to produce a file (or several files) based on other files.
Such custom build steps may be used for code generation - source files, private header files, public header files.

It's possible to build a tool for code generation, there is a special mechanism for doing this.
A package dependency may be specified as host package dependency.
Such package will be built for host system and its executables may be used in custom build steps.


### Dependencies isolation

Ü build system performs some tricks to manage dependencies of different versions and avoid conflicts of symbols from different libraries.

All functions of a build target which are not declared in public header files are internalized.
Doing so allows defining in different build targets internal functions with identical names without possible name conflicts in linking.
This also helps in later lik-time optimizations, since such functions may be inlined.

All functions from a private dependency are made private.
This allows using in two different build targets libraries with possible conflicting public functions or even two versions of the same build target (from different versions of a global versioned package).
This shouldn't lead to name conflicts during linking because of these libraries.

In cases where a build target recieves dependencies on different versions of a build target from a global versioned package, versions unification may be performed to avoid such conflicting dependencies.
This process changes versions of dependencies in some build targets until no conflicts are left.

For now there is a strange behavior caused by dependencies isolation approach described above.
If a build target is used privately by more than one other build targets and these build targets are linked into result executable or shared library, global mutable variables defined in the first build target may be duplicated. So, it's recommended to avoid using global mutable variables (it's general advice) or if it's necessary it's recommended to depend on a such build target only publically.


### Conclusion

All functionality described above was implemented in a couple of moths.
It required some extra changes in Ü compiler, mostly involving imports managing and symbols isolation.

The build system in current state should be useable, it's API is stable enough (or almost stable), no breaking changes should be done later.

The next big step is introduction of a centralized packages repository.
Logically global packages are already supported, it requires only creating such repository (which isn't an easy task) and implement packages downloading in the build system.
