---
title:  Auto return type functions
---

## Auto return type functions

### Introduction

A long time ago ( in year 2019 ) I added an experimental feature - return type of some functions may be marked as `auto`.
Return type for such functions is deduced automatically - based on the expression type of the `return` statement.

```
fn Foo( i32 x, i32 y ) : auto
{
    return x + y; // Return type is deduced to be "i32".
}
```

This worked only for non-class functions and was not so useful.
When writing Compiler1 i skipped this feature entirely.
So, it was almost abandoned.
Until recently.


### The second purpose of auto-return functions

Recently I added lambdas into the language.
Lambdas have one neat feature - reference notation for them is calculated automatically.
There is no need to specify it manually.

I found this feature useful not only for lambdas, but for other functions.
But how reference notation may be deduced for regular functions?
It's needed to run some kind of preprocessing, like for lambdas.
But such preprocessing already works for `auto`-return functions!
So, it was organically to add auto reference pollution deduction for `auto`-return functions.

Such change was pretty fast to implement - i just reused the code initially intended for lambdas to deduce reference notation also for `auto`-return functions.

```
struct S{ f32& x; }
// Return references is deduced to be "0a" (inner reference #0 of the arg #0).
fn Foo( S& s ) : auto&
{
    return s.x; // Return type is deduced to be "f32".
}
```

### auto-return methods

Until recently it was required for class completeness to have all its methods known (at least prototypes).
This was almost fine, but not for `auto`-return functions.
In order to know `auto`-return function type, its preprocessing needs to be run.
But such preprocessing almost always requires class completeness, which created dependency loop between a class and its `auto`-return method.
Because of this problem, `auto`-return methods were not allowed.

But after some thoughts i found, that all methods completeness isn't really required for class completeness.
Completeness required only for special methods (constructors, destructors, assignment operators) and virtual methods - in order to calculate some class properties and (for polymorph classes) to build the virtual methods table.
So, i changed this behavior.
And this made `auto`-return methods possible.

```
struct C
{
    u32 x;
    fn GetX( this ) : auto
    {
        return x; // Return type is deduced to be "u32".
    }
}
```

It's good to have such methods, but there are still some limitations.
`auto`-return special methods and virtual methods aren't allowed.
But it is fine, since such methods are rarely needed.


### Compiler1 improvements

After improving `auto`-return methods in Compiler0 i decided finally to implement them in Compiler1.
This was not a hard work and was done pretty quickly.

By implementing this feature in Compiler1 i finally managed to empty ignore tests list of Compiler1.


### Further work

With `auto`-return functions support in both compilers it was now possible to use `auto`-return in the `ustlib` and in Compiler1 code.
Especially `auto`-return is useful for template code in the `ustlib`.

First example: `min` and `max` functions.
They require reference notation for inner references of the result.
Such notation was a little bit verbose.
I rewrote these methods with usage of `auto`-return, and the result was shorter and more readable.

Second example: `make_array` and `make_tuple` functions.
These functions had no reference notation at all, because it was to complex to write such notation.
Now these methods are all `auto`-return and thus allow creating composite values with references inside.

Third example: after `auto`-return improvements i was managed to add the `iterator` class into the standard library.
This class uses `auto-return` for most of its methods.
I even delayed this class implementation after `auto`-return improvements, because it was too boilerplate to write it with reference-notation and return type manually specified.


### Conclusion

`auto`-return feature helps writing template library code.
It's recommended to use it in templates, where it allows to avoid specifying return type with complex `typeof` expressions and/or long reference notation expressions.

It's even better.
In some code, which calls user-defined function-like objects (lambdas, for example) it's almost impossible to write reference notation manually, based on the provided function-like object type.
