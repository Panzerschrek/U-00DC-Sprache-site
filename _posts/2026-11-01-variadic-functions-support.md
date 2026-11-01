---
title: Variadic function support
---

### Introduction

C has such feature (or more likely antifeature) as variadic functions.
It's basically a hack allowing passing variable number of arguments of arbitrary types into a function.
Back in times when C was developed it was a crude but working approach of doing that.

Notable variadic functions in C are `printf` and similar functions performing formatting.
But since such functions are supported, they are occasionally used for other purposes.

More modern language don't often have such functionality.
And languages which have it (as C++) have different mechanisms of achieving the same goal.
This includes template variadic functions (allowing creating a template with number of parameters determined at instatiation point).
Also this includes the ability to perform safe type erasure (enums like in Rust or `std::variant` in C++).


### Variadic functions in Ü

Ü is obviously a modern language and it doesn't require variadic functions.
It supports function overloading and function templates, which in case of a `printf`-like functionality allows passing variable number of arguments of arbitrary types.
Doing so is type-safe and one can't make silly mistakes typical for `printf` with possible errors in formatting string and/or passed arguments.

But recently I have found, that these exact C variadic functions are necessary in Ü.
But why?
The answer is simple: Ü needs to be able to call external C functions, which may be variadic.
This especially includes system APIs, like `open` function from Unix, which expects extra arguments if `O_CREAT` flag is passed.

But is it really necessary to have variadic functions support for doing so?
Previously I thought it isn't necessary.
I used a trick allowing calling C variadic functions from Ü, which is following: a prototype for an external variadic function is declared as having several extra parameters.
If no variadic arguments are necessary, zeros can be passed, otherwise real parameter values should be passed.
This approach worked well, since C calling convention requires the caller to push and pop arguments, so, if extra arguments are passed and the callee isn't aware of their presense, nothing bad happens.
Variadic arguments were passed as usual ones and all seemed to be fine.

All was fine, until I have found, that it's not the case.
On x86 and x86_x64 Windows/Linux systems and on Linux with AArch64 calling external variadic functions are described above worked fine.
But it didn't worked as expected on OS X with AArch64.
This caused among other things failing of some standard library tests on OS X.
And it wasn't easy to find, what was the problem, until I decided to compare assembler output of a C program calling a variadic and a non-variadic function.
Surprisingly code doing so isn't the same for OSX AArch64 builds.

So, in order to fix calling C variadic functions, I did need to implement their support.


### Implementation details

So, in Ü one can use `...` for declaring a variadic function.
Such functions are pretty limited: only `C` calling convention is supported, class member functions can't be variadic, no variadic template functions or coroutines are supported, marking a variadic function as `unsafe` is mandatory, etc.
Defining a variadic function in Ü is possible, but is practically useless, since no ways of accessing variadic arguments are implemented.

Calling a variadic function is possible as any other function.
But variadic arguments are handled specially.
They can be only simple scalars (fundamental types, enums, raw pointers).
Passing composites isn't supported.
Variadic arguments are assuming to be passed by value, so, no references can be passed.
Arguments of integer types are promoted to C `int` (as C requires).
`f32` is promoted to `f64`.

The most important thing is to use proper variadic flag for LLVM functions.
It's used later for code generation and its presense causes different code generation for variadic and non-variadic calls on OS X with AArch64 architecture.

After the changes above was implemented, corresponding pieces of the Ü standard library (which used some variadic C system functions) were corrected.
And this worked well!
Failures of some tests on OS X were fixed!


### Conclusion

Now Ü is capable of call variadic C functions properly (with correct ABI).
This allows using system APIs using such functions.
Surprisingly this affects mostly Unix APIs, WinAPI doesn't use variadic C functions, it uses a calling convention incapable of supporting variadic arguments.

Even if Ü can call external variadic functions, it isn't able to access variadic arguments.
There is no equivalent for C `va_start`/`va_arg`/`va_arg` macros.
It's done intentionally, so that no one can do this nasty C-like approach in Ü, even if one wishes to do so.
It's unsafe, and has performance implications.
If it's necessary to pass variadic number of arguments with arbitrary types, Ü provides better means of doing this.
