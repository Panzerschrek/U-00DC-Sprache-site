---
title:  Functions visibility evolution
---

## Functions visibility evolution

In this article i will explain, how functions (and not only functions) visibility evolved during Ü development.


### Initial approaches

Ü language development was started in year 2016.
But active development was started only in year 2017.
In this year LLVM library was introduced for code generation.

Initially all functions had _external_ linkage, as (for example) any regular (non-template, non-static and non-inline) C++ functions.
This was a default behavior, there was no reason to choose something else.

In November 2017, after templates and imports were introduced, functions linkage was changed.
This was needed in order to avoid _redefinition_ linking errors while linking files containing identical instantiations of same templates.
From now _linkonce_odr_ was used, together with _comdat any_.
Such approach allowed to work with templates and even treat all functions, defined in common imported files, as sort of _inline_.


### Moderate approach

Approach above was used pretty long.
It lasted even during development of Compiler1 (year 2020).

During Compiler1 development i noticed, that its build became slower and slower.
Initially i thought, that this was because of class templates model in Ü - each class template instantiation produces all methods, even if some methods were not used.
Anyway, even with such slow compilation i managed to reach Compiler1 self-building.
After that i decided to fix its slow compilation.

I found, that there was really a lot of template methods in result code.
But methods generation itself was pretty fast.
Much slower it was to compile all this methods into machine code.
But do we really need to generate machine code for all there methods?
Not at all!

Since some template methods are not used, it is safe to just remove them!
LLVM optimizer can remove unused methods, but only if they have _private_ linkage.
_linkonce_odr_ linkage and _comdat_ are not needed, because template must be instantiated in each compilation unit, thus each user of template will get its own copy of template methods code.

So, i changed functions linkage from _linkonce_odr_ to _private_ for each function, located inside template.
Also i changed linkage to _private_ for all generated methods of regular classes.

The result was shocking - Compiler1 build became several times faster!
It took now about 30 seconds to build Compiler1, instead of several minutes.
Debug builds became much faster too.


### Advanced approach

Approach above was good, but not good enough.

I found, that Ü compiler is missing very important feature - regular functions with _private_ visibility, like _static_ functions in C++.
It was even necessary, since with _linkonce_odr_ visibility it was possible to accidentally define function with same name (and signature) in different compilation units and **silently** merge them together during linking without noticing it and thus break result program.

In July 2023 i decided to fix these issues.

I decided, that location of the function declaration/definition may be used to control its visibility.

If function is defined inside non-main (imported) file, it may be safely made _private_.
If you need to use this function - just import file with its definition.
If you import a file with a bunch of function definitions and use only some of them, other functions will be optimized-out.

But what if function with _private_ visibility is needed inside main (compilation root) file?
I found a solution for this problem.
A function may be done _private_ if it has no prototypes in imported files.
It has a reason.
_external_ visibility is needed, when function defined in one compilation unit is used in another compilation unit.
But in order to do this function prototype must be declared in common imported file.
So, if you use declarations inside common file, you get _external_ visibility automatically.

So, new approach for functions visibility is following:

* Every generated function is _private_
* Every function inside template is _private_
* Every function defined in imported file is _private_
* Function defined in main file is _private_, unless it has a prototype in one of imported files
* Function defined in main file, that has a prototype in one of imported files, has _external_ linkage
* _nomangle_ function defined in main file has also _external_ linkage, even if no prototype in any imported file exists

Additionally approach above was used for some non-function symbols:

* Every immutable global variable is _private_
* Mutable variable, defined in imported file, is _external_ and has a _comdat_ (for deduplication)
* TypeID table for polymorph classes is _private_, if class is declared i main file, otherwise it is _external_ and has a _comdat_
* Polymorph classes virtual table is always _private_

With following approach it is now impossible to obtain silent merge of distinct functions during linking.
_external_ linkage without a comdat will prevent it.
And creation of _private_ function is now as simple as it can be - just define a function and it will be _private_, unless you create also a declaration in another file for it.


## Conclusion

Now Ü has reliable and configurable functions visibility model.
Especially good is that no special language constructions are required to control visibility (_static_, like in C++, _pub_, like in Rust).

Current behavior is also friendly for compilation speed and runtime performance.
Preferred usage of _private_ linkage by Ü Compiler allows to reject unused functions and thus speed-up build/reduce object files size.
Also usage of _private_ linkage allows LLVM optimizer to more-aggressively inline functions and thus increase performance of result code.

Will current linkage model change?
It is likely (as history shows), but i think that it will no change so drastically as before.


## Links

[More about linkage types](https://releases.llvm.org/15.0.0/docs/LangRef.html#linkage-types)
