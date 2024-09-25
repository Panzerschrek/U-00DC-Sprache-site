---
title:  Auto-move in return
---

## Auto-move in return

### Motivation

In the Compiler1 code it was usual to write code like this:

```
var SomeStruct mut s{ .x= InitX(), .y= InitY() };
return move(s);
```

`return move` was a common pattern in order to avoid taking copies in `return`.
But it's too verbose, so, i decided to change this.


### Solution

Actually the compiler can automatically detect cases, where a local variable is returned and move it without explicit `move` operator.
Recently i implemented exactly this behavior.

Now `return some_var;` behaves in certain circumstances like `return move(some_var);`.
`some_var` should be the name of a local variable or value argument.
This variable should not have alive references to it.
Compared to regular `move` auto-move in `return` may also move immutable variables.

Automatic move in more complex cases is still not possible.
For example `return Foo(some_var);` can't be transformed into something like `return Foo(move(some_var));`.
So, `move` should be still specified manually.

Automatic move works also in cases where implicit type conversion is performed:

```
struct S
{
	i32 x;
}
struct T
{
	fn conversion_constructor( S mut in_s ) ( s(move(in_s)) ) {}
	S s;
}
fn MakeT( S s ) : T
{
	return s; // Auto-move in "return" and than perform implicit type conversion.
}
```


### Conclusion

Adding such easy feature allows to simplify code in many places.
Writing `return move` isn't needed anymore.
Yet another benefit - in some cases it's not longer needed to declare returned variable as mutable.

So, code like in the beginning of this post now looks like this:


```
var SomeStruct s{ .x= InitX(), .y= InitY() };
return s;
```


### Future work

Automatic move in `return` is nice, but it's still a partial solution.
More general solution is to analyze variables lifetime and move them automatically at last usage.
This may eliminate need for `move` at all or at least almost in all cases.
But for now it's too complicated. It requires substantial compiler architecture changing - introducing a whole new pass to analyze lifetimes, which isn't so trivial.
