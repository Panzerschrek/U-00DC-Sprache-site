---
title:  Dead code checks
---

## Motivation

Ü is pretty restrictive language.
For example, there are no explicit type conversions, reference-checking ensures absence of memory errors, there are a lot of class members and inheritance consistency checks, etc.
But until recently there were no dead-code related checks.

Modern C++, for example, has such checks - enabled via special warning flags.
Rust has such checks too.
So, i decided to add dead code checks in Ü.
The main reason to do this - find potential error in programs.
Dead code itself is not so bad, but its presence may indicate, that something is wrong.


### Useless expressions detection

One of possible function/block body elements is a simple expression element.
It is designed primary for cases, like calling functions with side-effects.
But syntactically nobody prevents a programmer to use other kinds of expressions but function calls.

Using such expressions has no practical purpose in real programs.
Presence of such expression may indicate some inconsistency in the program and (possible) an error.
So, i decided to generate compilation errors, when an expression with side effect is detected.

Now a special compilation error is generated, if the root of a simple expression is following:

* any binary operator
* any unary prefix operator
* member access
* indexing (`[]`)
* reference to pointer and pointer to reference conversions
* named operand
* literal constants (numbers, boolean values, strings)
* all cast operators
* all type names in expression context

Function call is considered not to be useless, even if such calls are constexpr.
`select` operator is considered useless, because in most cases it produces a value, than needs to be handled.
`if` operator may be used instead of `select` with simple expression root.
`safe` and `unsafe` expressions are inspected deeply.

Some examples:
```
var i32 x= 0, y = 0;
a + b; // Error - binary operator has no sense.
var [i32, 4] arr= zero_init;
arr[42]; // Indexing an array has no effect - error.
select( true ? a : b ); // Error - result of 'select' is not used.
cast_imut(x); // Error - useless cast.
true; // Useless boolean constant.
42; // Useless numeric constant
"some_string"; // Useless string constant.
tup[ i32, f32 ]; // Useless tuple type name.
y; // Useless named operand.
unsafe( x ); // Still useless.
SomeFunction(); // Ok - call function.
```


### Unused names detection

Detecting unused names is important too.
Unused code may indicate that something in a program is wrong - for example programmer forgot to use a variable or forgot to remove it during a refactoring.

So, i implemented some kind of unused names detection in Ü.
Internally there are two kinds of checks - for local (function scope) names and other (global) names.

Local unused names detection is implemented for type aliases, function arguments, local variables and references.
A name is considered to be unused if it was never referenced (including referencing inside non-compiled `static_if` branches).

But there is an exception in this rule.
Some local variables and function value-arguments that are never referenced still may be needed.
For example, if a variable has non-trivial destructor (with side effects).
If such variable is defined, it may be still useful and it is normal for it to remain unreferenced.
But how to distinguish between trivial and non-trivial destructor?
This is a hard problem and it is not solved in Ü yet.
Now all variables with a destructor that does at least something considered to be used.
This is better than nothing, but such wide criteria allows variables with some commonly-used types to be unused, like `ust::vector` or `ust::string` - where destructor does nothing special but freeing a memory.

Global name detection is implemented for global variables, type aliases, structs/classes, enums, type templates, functions, class fields.
For functions and type templates usage check is performed per-item for set of things with same name.
For example, if two overloaded functions with same name are declared, but only one is used (called or assigned to a function pointer) - an error about unused second function will be generated.

It is important to mention, that global unused names check is performed only in things, declared inside main file (compilation root), but not for imported files.
There is no reason to perform unused names check for imported files, since such files may be imported in other main (compiled) files and unused in this compilation unit names may be used in other files.

There are a couple of exceptions for unused functions.
Special class methods - default constructor, copy construcotr, copy-assignment operator, equality-compare operator, destructor may be unused, but no error will be generated for them.
It is needed, since presence of such methods affects some important class properties.
`nomangle` functions and functions with prototype in one of imported files are considered used.
For now all virtual functions considered to be used, but only because it is hard to perform usage check for them.

Class fields are considered unused, if they are referenced outside initialization code.
If a field is initialized inside member access operator and/or inside class constructor initialization list, but not used later - an error for it will be generated.


#### Consequences of unused names detection introduction

After introduction of unused names check i found, that such check affects a lot of code of tests and Compiler1.

First, almost every test in `cpp_tests` and `py_tests` is now wrong, since a majority of tests contains a single local function or even contain no functions at all.
So, i needed to make unused names detection check optional and have disabled it for all these tests.

Second, some linkage tests build was broken.
I managed to fix some of them and disable unused names check for other tests.

Third, ustlib and Compiler1 build was broken too.
In most cases this was due to unused function arguments.
Almost all these cases were legit - arguments needed to be unused.
In order to silence such false-positives i added a special function into ustlib - `ignore_unused`.
This function does nothing but silences errors about unused variables.


### Conclusion

Some places in Compiler1 needed to be changed after introducing checks, mentioned above.
I managed to find a couple of places with real bugs and more places with unused function arguments (that may be removed).

This proves that dead code checks are useful.

Rarely unused names are still useful.
For example, a struct field may be useful, if this struct is used for communication with foreign language code.
Or, if some code is not finished yet.

There are a couple of ways to deal with it.
First - it is possible to disable unused names check via special compiler option.
Second (perfected way) - unused code may be move into an imported file.
