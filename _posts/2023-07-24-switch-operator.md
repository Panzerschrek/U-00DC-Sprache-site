---
title:  Switch Operator
---

### Motivation

Sometimes it is necessary to compare some value against fixed set of other values and execute some code, specific for each value.
Example from Compiler1 code:

```
if( t == U_FundamentalType::i8_	 ) { return KeywordToString( Keyword::i8_	); }
if( t == U_FundamentalType::u8_	 ) { return KeywordToString( Keyword::u8_	); }
if( t == U_FundamentalType::i16_ ) { return KeywordToString( Keyword::i16_	); }
if( t == U_FundamentalType::u16_ ) { return KeywordToString( Keyword::u16_	); }
if( t == U_FundamentalType::i32_ ) { return KeywordToString( Keyword::i32_	); }
if( t == U_FundamentalType::u32_ ) { return KeywordToString( Keyword::u32_	); }
if( t == U_FundamentalType::i64_ ) { return KeywordToString( Keyword::i64_	); }
if( t == U_FundamentalType::u64_ ) { return KeywordToString( Keyword::u64_	); }
```

Another example:
```
auto escaped_c= it.front();
it.drop_front();
if( escaped_c == "\""c8 || escaped_c == "\\"c8  )
{
	result_lexem.text.push_back( escaped_c );
}
else if( escaped_c == "b"c8 ){ result_lexem.text.push_back( "\b"c8 ); }
else if( escaped_c == "f"c8 ){ result_lexem.text.push_back( "\f"c8 ); }
else if( escaped_c == "n"c8 ){ result_lexem.text.push_back( "\n"c8 ); }
else if( escaped_c == "r"c8 ){ result_lexem.text.push_back( "\r"c8 ); }
else if( escaped_c == "t"c8 ){ result_lexem.text.push_back( "\t"c8 ); }
else if( escaped_c == "0"c8 ){ result_lexem.text.push_back( "\0"c8 ); }
else if( escaped_c == "u"c8 )
{
    // ...
```
As you can see, such code is implemented via chains of `if-else` operators.
And such chain looks not so great (too verbose).

So, in order to beautify such code i decided to add into Ü something like `switch` operator from C++.
Such operator may be shorter than equivalent chain of `if-else`.

Initially i thought to implement it via some library/built-in macro.
Such macro may look like true `switch` operator, but internally will produce same chain of `if-else`.

But i found some reasons not to do that.
I decided to implement `switch` operator as a part of the language.
Later i will explain why.


### Implementation

So, simple `switch` operator in Ü looks like this:

```
switch(x)
{
    0 -> { return 42; },
    1 -> { ++y; },
    2 -> { foo(); },
    default -> {}
}
```

Such operator compares value in `()` against values before `->`.
If values are equal, control flow is passed to the block after `->`.
If no matching value found, control flow is passed to `default` block.

But what is the difference between such `switch` and `if-else` chain?
There are a lot of differences!

It is possible to specify multiple values:

```
switch(x)
{
    0, 10, 66 -> { return 42; },
    15, 16 -> { ++y; },
    21, 22, 100, 500 -> { foo(); },
    default -> {}
}
```

It is similar to using multiple `case` labels in C++ `switch`.

Ranges are also possible, including half-open ones:

```
switch(x)
{
    0 ... 10, 100 ... 1000 -> { return 42; },
    ... -16, 33 -> { ++y; },
    9999 ..., 77, 99 -> { foo(); },
    default -> {},
}
```

In C++ `switch` there are no ranges in the standard.
They exist only as extensions in some compilers (like GCC).


### The Main Feature

Ok great, `switch` in Ü is pretty flexible.
But this is not a main feature of the `switch` operator.
There is something else.

The `switch` operator has though some limitations.
It supports only integer, character and `enum` types.
And it supports only `constexpr` label values.
So, it is not so flexible (in some cases), like `if-else` chain.

But such limitations have a good reason.
Because all values are compile-time constants and are internally just integer numbers, Ü compiler can statically check, if all possible values are handled inside `switch`!

So, if you forget to handle some values, compiler will complain about it:

```
fn Foo( i32 x ) : i32
{
    switch(x)
    {
        0, 1, 2 -> { return 42; },
        3, 4, 5 -> { return 24; },
        // Compilation error - values before 0 and values after 5 are not handled.
    }
}
```

You need to specify such values manually (one by one or via ranges) or add a `default` branch:

```
fn Foo( i32 x ) : i32
{
    switch(x)
    {
        0, 1, 2 -> { return 42; },
        3, 4, 5 -> { return 24; },
        default -> { return 0; }, // Ok - all other values are handled in "default" branch.
    }
}
```

There is another kind of check.
The compiler will complain, if default branch is unnecessary:

```
enum E{ A, B, C }
fn Foo( E e ) : i32
{
    switch(e)
    {
       E::A -> { return 123; },
       E::B -> { return 456; },
       E::C -> { return 789; },
       default -> { return 0; }, // Compilation error - default branch is unreachable. Ü assumes that only values listed in the enum declaration are possible.
    }
}
```

Also compiler can check for overlaps/duplicate values:

```
fn Foo( i32 x ) : i32
{
    switch(x)
    {
        5-> { return 1; },
        3 + 2 -> { return 2; }, // Error, label value `3 + 2` is equal to value of other label `5`.
        10 ... 20 -> { return 3; },
        19 ... 1000 -> { return 4; }, // Error, this range overlaps with previous one.
        default -> { return 0; },
    }
}
```

### Reason for static checks

So, why exactly `switch` in Ü has such checks?
The main reason for that is code safety.
It is better to perform code static checks during compilation instead of spending time debugging/testing it.
If it is possible, programmer can use `switch` and get all its checks.
If not - it is still possible to use chain of `if-else`.

Especially useful are static checks for enums.
Consider such example:

```
enum E{ A, B, C }
```
```
// Some function, defined far away from the enum definition, possible in another file/library.
fn Foo( E e ) : i32
{
    switch(e)
    {
       E::A -> { return 123; },
       E::B -> { return 456; },
       E::C -> { return 789; },
    }
}
```

All works, all are happy.
But one day declaration of the enum changes - new values are added:

```
enum E{ Before, A, B, C, AfterC }
```

And after such addition compilation of the function with `switch` breaks with a message like this:

```
test.u:6:10: error: Value 0 is not handled in switch.
test.u:8:10: error: Value 4 is not handled in switch.
```

And it is great, that compilation breaks!
If no such static checks existed, the program will successfully compile, but contain a bug in place of this switch.
And it may take long time to find and fix this bug.
But with such static checks it is trivial to find all such places and fix them:

```
fn Foo( E e ) : i32
{
    switch(e)
    {
       E::Before -> { return 999; },
       E::A -> { return 123; },
       E::B -> { return 456; },
       E::C -> { return 789; },
       E::AfterC -> { return 1; },
    }
}
```

Alternatively it is possible to add a `default` branch.
But such solution may not be safe, since after another enum values will be introduced no new compilation errors will be generated and it may be not so easy to find places in code needed to be changed.

Ü is not unique with such static checks.
Some modern C++ compilers can also complain about unhandled enum values in `switch`.
Rust compiler will also complain about unhandled variants in `match` operator, though `match` in Rust works internally very differently relative to `switch` in Ü.


### Conclusion

Now `swith` operator is available.
It is recommended to use it where it is possible.

With such `switch` operator i managed to rewrite some boilerplate code in Compiler1 (like in some examples in the beginning of this article).

Some small bonus:
`switch` operator is also useful with only a couple of handler blocks, but many values.
It is still better that writing chain of `==` and `||`.

Code before:

```
fn IsWhitespace( char32 c ) : bool
{
	return
		c == " "c32 || c == "\f"c32 || c == "\n"c32 || c == "\r"c32 || c == "\t"c32 ||
		c <= char32(0x1Fu) || c == char32(0x7Fu);
}
```

Code after:

```
fn IsWhitespace( char32 c ) : bool
{
	switch(c)
	{
		" "c32, "\f"c32, "\n"c32, "\r"c32, "\t"c32, char32(0x1Fu), char32(0x7Fu) -> { return true; },
		default -> { return false; }
	}
}
```
