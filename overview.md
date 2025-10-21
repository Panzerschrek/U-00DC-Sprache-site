## Ü overview

Ü is a programming language designed primary for applications, where speed and safety are both important.
It is heavily inspired by C++, a little bit by Rust and tries to fix some disadvantages of these languages.

The main goals of Ü language development are good performance, minimizing of bugs possibility, good balance between readability and expressiveness.

This article contains a short overview of most important Ü features.


### Compilation into machine code

Good performance is achievable only via compilation into native code.
Interpretation or virtual machine (even with JIT) is too slow.
Because of that Ü targets machine code.

Ü compiler is based on LLVM library and thus uses the whole LLVM infrastructure.
It can support whatever processor architecture that is supported by LLVM.


### Context-free syntax

The syntax of Ü is context-free, that simplifies compiler development and makes code more readable.
The only exception are macros, which allow to extend syntax in a limited way, but such macros depend only on their definition and not things like type system and other information not available at parsing stage.


### Order-independent top level definitions

Ü compiler is smart enough to perform symbol tables preevaluation.
Thus reverse definitions order (like in C) and (sometimes) prototypes usage may be avoided.


### Imports model

`import` in Ü means compilation of a specified file and logical merging of the result into current compilation unit.
All imported files are compiled independently on each other, rather than merging file contents together and compiling this "as is", as (for example) C++ compiler does.
All contents of imported files is considered to be inline - no special `inline` keyword is required.

It is important to mention that imports in Ü are designed for usage of separate header/implementation files.
It is recommended to do such, but it is still possible to use "header-only" files.
Import dependency loops are not possible.

The model with preferred usage of "headers" may seem to be outdated, but in reality it forces to decouple interface from implementation details and improves readability of the interface part.


### Straightforward types evaluation model

Types of all function parameters/function return values, class fields must be specified explicitly.
Types for variables may be specified, but it is possible to avoid type specifying via `auto`.
There are also a couple of constructions where it is unnecessary to specify types, but mostly they must be specified.

There is no complex type calculation mechanisms.
This improves code readability and significantly simplifies the compiler.


### Static strong typing

Static typing is a necessity for good performance.
Thus Ü uses static typing system.
It is not only static, but (almost) strong.
Type conversions between fundamental types are always explicit.
But it is possible to use some sort of auto-conversion for user-defined types.

Static strong type system is one of necessary requirements for achieving safety.
With any other kind of type system it is almost impossible to write reliable error-free code.


### Memory safety

Ü features clever mechanism named *reference checking*, that ensures memory correctness during compilation.
If code is incorrect, compilation fails with an error.
If compilation succeeded, result program should not contain any memory errors, like use after free, out of bounds access, etc.

It is still possible to shot the leg via `unsafe` blocks/expressions/functions, but it is strongly recommended to use `unsafe` as little as possible.

The same mechanism, that ensures memory safety, is also used to ensure thread safety.

There are of course some disadvantages of this mechanism.
Special notation for functions and class fields is sometimes required, that may seem to be a little bit verbose.
Some (uncommon) code patterns are not (effectively) achievable in Ü without usage of `unsafe`.
But in most cases usage of `unsafe` is rarely needed - mostly for interaction with foreign code.


### Mandatory initialization

Each fundamental type variable/field should be initialized.
This prevents bugs caused by uninitialized memory reads.
User types initialization is also required, but it may be omitted if a user type has default constructor.


### Simple reference model

Ü has support of reference-variables, fields, function parameters and return values.
Usage of references is simple - there is no need for manual/boilerplate take reference/dereference operators, like for C pointers or Rust references.
It is much like in C++.
But for code simplicity references are not a part of the type system, rather than a part of variable/field declarations, function signatures.


### Assignment/copying model

Ü supports copying/assignment via just `=` for many types, including user types (if `=` is defined).
There is no need to call something like `clone` to create a copy of a value.

But Ü is still effective and allows to avoid unnecessary copying.
Temporary values are effectively moved, named variables may be moved manually via `move` operator.


### No memory-dependent objects

Objects in Ü have no specific defined memory location, as (for example) C++ requires.
This allows to move objects effectively from one location to another and thus speed-ups result code.
In terms of C++ this means, that no non-trivially-relocable types are allowed.


### Constructors

Ü supports special structure/class methods named `constructor`, which are called during initialization.
Usage of constructors is almost like in C++.
This seems to be more elegant way of initialization, compared to factory functions like in Rust.


### Destructors

One of the most important features of Ü is usage of destructors.
A `destructor` is a special method which is automatically called for a variable at its lifetime end.

Usage of destructors allows to implement robust and safe memory and resource management without relying on slow and complex garbage collection schemes.


### Functions overloading

Ü supports defining functions with same name in same scope, as soon as their signatures are different.
This allows to avoid boilerplate by defining different names/name suffixes for functions that do almost the same except of a couple of details.


### Operators overloading

It is possible to overload operators (unary, binary, postfix) for user types.
Such feature allows for code to be expressive and compact simultaneously.


### Methods generation

Ü allows to avoid boilerplate code by generating some methods for user types automatically.
This includes destructors, default-constructors, copy-constructors, copy-assignment operators, equality compare operators.


### Rich type system

Ü has basic set of built-in types and some ways to create composite types.

Ü has several type categories:

* fundamental scalars - integers (signed and unsigned), floating point, chars, bytes, bool, void
* arrays with fixed size (known at compile-time)
* tuples
* structs and classes
* enums - simple types with fixed set of possible predefined named values (much like in C++, but stricter)
* function pointers
* raw pointers (for unsafe code and foreign code interaction)

These type kinds are sufficient to express any other complex data structures.


### Compile-time polymorphism

Ü has both type and function templates, that enables to define abstract data structures, abstract functions, much like C++ does.

Important feature of Ü templates is duck-typing.
There are no traits/type requirements in templates.
If a template performs some operation over given type (operator, copying, method call), code compiles, if given type supports such operations and doesn't compile - if not.
Such system requires less boilerplate for both template authors and template users.

There are some drawbacks of this scheme, like no errors check for non-instantiated templates.
But it seems to be not so important.
If it is necessary, something like generics and traits may be added in future.


### Runtime polymorphism via inheritance

Ü supports inheritance for classes and virtual methods.
It is similar to C++, but is stricter, that allows to avoid some mistakes.

Inheritance in Ü uses zero or one base and zero or many interfaces model.

Inheritance is enabled only if necessary - if a class has ancestors or is defined as polymorph.
This allows for most classes not to be polymorph and thus to avoid polymorhpism overhead (for virtual table pointers, for example) where it is not necessary.


### No exceptions

Ü has an advantage of absence of exceptions.
No exceptions means no hidden control flow and no possibility to silently ignore errors.
This allows to improve overall code reliability.

The absence of exceptions also improves runtime performance (comparing to languages with exceptions) and reduces result executables size.


### Compile-time evaluation

Ü supports compile-time evaluation via `constexpr` mechanism.
Simple expressions and calls to `constexpr` functions with all arguments - compile-time constants are evaluated in compile-time.

A function may be marked as `constexpr` if it uses safe and deterministic subset of Ü - no `unsafe`, no memory allocations, no runtime polymorphism.


### Compile-time type information

Ü provides special operator `typeinfo` for type inspection.
Together with `constexpr` evaluation it allows to write template code with different behavior specially designed/optimized for different types/type kinds.


### Mixins as ultimate metaprogramming solution

Ü provides arbitrary compile-time code generation - via mixin strings.
This allows to generate any Ü code in compilation time and thus almost eliminates the need for any external code generation tools/scripts.
Some code, impossible with templates, is possible to generate using mixins.


### Code structuring via namespaces

Ü supports namespaces like in C++.
Namespaces may be used in different files, they may be opened and closed multiple times, nested namespaces are possible.
The mechanism of namespaces allows to structure code independent on project files structure.


### Async functions

Ü has async/await mechanism like many other programming languages have.
Since Ü is relatively fast, it allows to write effective concurrent programs for networking (and not only), with large throughput and good CPU utilization.


### Lambdas

Ü supports anonymous functions with context capturing.
Such functions are named lambdas.
They are useful in combination with functions/algorithms accepting a function-like object.
It's much easier to pass a lambda, rather than creating a separate class with overloaded `()` operator for only single use.
