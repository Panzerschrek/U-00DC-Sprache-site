---
title: Variadic function support
---

### Introduction

C has such feature (or more likely antifeature) as variadic functions.
It's basically a hack allowing passing variable number of arguments of arbitrary types into a function.
Back in times, when C has been developed, it was a crude but working approach of doing this.

Notable variadic functions in C are `printf` and similar functions performing formatting.
But since variadic arguments are present in the language, they are occasionally used for other purposes. Some well-known APIs and libraries do this.

More modern languages don't often have C-style variadic functions.
And languages which have them (as C++) have different mechanisms of achieving the same goal.
This includes template variadic functions (allowing creating a template with fixed number of parameters determined at instatiation point).
Also this includes the ability to perform safe type erasure (enums like in Rust or `std::variant` in C++).


### Variadic functions in Ü

Ü is obviously a modern language and it doesn't require C-style variadic functions.
It supports function overloading and function templates, which in case of a `printf`-like functionality allows passing variable number of arguments of arbitrary types.
Doing so is type-safe and one can't make silly mistakes typical for `printf` with possible errors in formatting string and/or passed arguments.

But recently I have found, that these exact C variadic functions are necessary in Ü.
But why?
The answer is simple: Ü needs to be able to call external C functions, which may be variadic.
This especially includes system APIs, like `open` function from Unix, which expects an extra argument if `O_CREAT` flag is passed.

But is it really necessary to have variadic functions support for doing so?
Previously I thought, that it isn't necessary.
I used a trick allowing calling C variadic functions from Ü: a prototype for an external variadic function is declared as having several extra parameters of integer types.
If no variadic arguments are necessary, zeros can be passed, otherwise real parameter values should be passed.
This approach worked well, since C calling convention requires the caller to push and pop arguments, so, if extra arguments are passed and the callee isn't aware of their presence, nothing bad happens.
Variadic arguments were passed as usual ones and all seemed to be fine.

All was fine, until I have found, that it's not true in all cases.
On x86 and x86_x64 Windows/Linux systems and on AArch64 Linux calling external variadic functions as described above worked fine.
But it didn't work as expected on OS X with AArch64 architecture and caused among other things failing of some standard library tests.
And it wasn't easy to find, what was the problem, until I decided to compare assembler output of a C program calling a variadic and a non-variadic function.
Surprisingly code doing so isn't the same for OSX AArch64 builds - different registers are used for passing arguments.

So, in order to fix calling C variadic functions, I did need to implement their proper support.


### Implementation details

So, now in Ü `...` at the end of a function's parameters list can be used for declaring a variadic function.
Such functions are pretty limited: only `C` calling convention is supported, class member functions can't be variadic, no variadic template functions, lambdas or coroutines are supported, marking a variadic function as `unsafe` is mandatory, etc.
Defining a variadic function in Ü is possible, but is practically useless, since no ways of accessing variadic arguments are implemented.

Calling a variadic function is possible as any other function.
But variadic arguments are handled specially.
They can be only simple scalars (fundamental types, enums, raw pointers).
Passing composites isn't supported.
Variadic arguments are assuming to be passed by value, so, no references can be passed.
Arguments of integer types are promoted to C `int` (as C requires).
`f32` is promoted to `f64`.

The most important thing is to use proper variadic flag for LLVM functions.
It's used later for code generation and its presence causes different code generation for variadic and non-variadic calls on OS X with AArch64 architecture.

After the changes described above have been implemented, some bits of the Ü standard library (which used some variadic C system functions) have been corrected.
And this worked well!
Failures of some tests on OS X have been fixed, which indicates, that the root cause of these failures has been correctly identified and eliminated.


### Conclusion

Now Ü is capable of calling variadic C functions properly (with correct ABI).
This allows using system APIs using such functions.
Surprisingly this affects mostly Unix APIs, WinAPI doesn't use variadic C functions, it uses a calling convention (*stdcall*) incapable of supporting variadic arguments.

Even if Ü can call external variadic functions, it doesn't provide means for accessing variadic arguments.
There is no equivalent for C `va_start`/`va_arg`/`va_arg` macros.
It's done intentionally, so that no one can do this nasty C-like approach in Ü, even if one wishes to do so.
It's unsafe, and has performance implications.
If it's necessary to pass variadic number of arguments with arbitrary types, Ü provides better means of doing this.
