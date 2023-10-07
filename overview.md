## Ü overview

Ü is a programming language designed primary for applications, where speed and safety are both important.
It is heavily inspired by C++, a little bit by Rust and tries to fix some disadvantages of these languages.


### Compilation into machine code

Good performance is achievable only via compilation into native code.
Interpretation or virtual machine is too slow.
Because of that Ü targets machine code.

It is based on LLVM library and thus an use whole LLVM infrastructure.
Ü compiler support whatever processor architecture that is supported by LLVM.


### Context-free syntax

Syntax of Ü is context-fee, that simplifies compiler development and makes code more readable.


### Order-independent top level definitions

Ü compiler is smart enough to perform symbol tables preevaluation.


### Imports model


### Straightforward types evaluation model

Types of all function parameters/function return values, class fields must be specified explicitly.
Types for variables may be specified, but it is possible to avoid type specifying via `auto`.
There are also a couple of constructios where it is unnecessary to specify types, but mostly they must be specified.

There is no complex type calculation mechanisms.
That significantly simplifies compiler and improves readability.


### Static strong typing

Static typing is a necessity for good performance.
Thus Ü uses static typing system.
It is not only static, but (almost) strong.
Type conversions between fundamental types are always explicit.
But it is possible to use some sort of auto-conversion for user-defined types.

Static strong type system is one of requirements for safety.
With any other kind of type system it is almost impossible to write reliable error-free code.


### Memory safety

Ü features clever mechanism named "reference checking", that ensures memory correctness during compilation.
If code is incorrect, compilation fails with an error.
If compilation succeeded, result program should not contain any memory errors, like use after free, out of bounds access, etc.

It is still possible to shot the leg via `unsafe` blocks/expressions/functions, but it is strongly recommended to use `unsafe` as little as possible.

Same mechanism that ensures memory safety may be used to ensure thread safety.


### Mandatory initialization

Each fundamental type variable/field should be initialized.
This prevents bugs caused by unitialized memory reads.
User types initialization is also required, but it may be omitted if user type has default constructor.


### Simple reference model

Ü has support of reference-variables, fields, function parameters and return values.
Usage of references is simple - there is no need for manual/boilerplate take reference/dereference operators, like for C pointers or Rust references.
It is much like in C++.
But for code simplicity references are not part of type system, rather than part of variable/field declarations, function signatures.


### Assignment/copying model

Ü supports copying/assignment via just `=` for many types, including user types (if `=` is defined).
There is no need to call something like `clone` to create copy of a value.

But Ü is still effective and allows to avoid unnecessary copying.
Temporary values are effectively moved, named values may be moved manually via `move` operator.


### Constructors

Ü supports a special structure/class methods named `constructor`, that are called during initialization.
Usage of constructors is almost like in C++.
This  seems to be more elegant way of initialization, compared to factory functions like in Rust.


### Destructors

One of the most important features of Ü is usage of destructors.
`destructor` is a special method this is automatically called for variable at lifetime end.

Usage of destructors allow to implement robust and safe memory and resource management without relying on slow and complex garbage collection schemes.


### Functions overloading

Ü supports defining functions with same name in same space, as soon as parameter types differs.
This allows to avoid boilerplate by definig different names/name suffixes for functions that do almost the same except a couple of details.


### Operators overloading

It is possible to overload operators (unary, binary, postfix) for user types.
Such feature allows for code to be expressive and compact simultaneously.


### Methods generation

Ü allows to avoid boilerplate code by generating some methods for user types automatically.
This includes destructors, default-constructors, copy-constructors, copy-assignemt operators, equality compare operators.


### Compile-time polymorphism

Ü has both type and function templates, that enables to define abstract data structures, abstract functions, much like C++ does.

Important feature of Ü templates is Duck-typing.
There are no traits/type requirements in templates.
If a template performs some operation over given type (operator, copying, method call) code compiles if given type supports such operations and doesn't compile - if not.
Such system requires less boilerplate for both template autos and template users.

There are some drawbacks of this scheme, like no errors check for non-instantiated templates.
But it seems to be not so important.
If it is necessary, something like generics and traits may be added later.


### Runtime polymorphism via inheritance

Ü supports inheritance for classes and virtual methods.
It is similar to C++, but is stronger, that allows to avoid some mistakes.

Inheritance in Ü uses zero or one base and zero or many interfaces model.

Inheritance is enabled only if necessary - if class has ancestors or is defined as polymorph.
That allows for most classes not to be polymorph and thus avoid polymorhpism overhead (for virtual table pointers, for example) where it is not necessary.


### No exceptions

Ü has an advantage of absence of exceptions.
No exceptions means no hidden control flow and no possiblity to silently ignore errors.
This allows to improve overall code reliability.

The absence of exceptions also may improve result performance and reduce result executables size.
