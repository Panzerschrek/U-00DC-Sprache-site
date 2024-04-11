---
title:  Auto-move in return
---

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
Recently i added exactly this behavior.

Now `return some_var;` behaves in curtain circumstances like `return move(some_var);`.
`some_var` should be the name of a local variable or value argument.
This variable should not have alive references to it.
Compared to regular `move` auto-moving in `return` may also move immutable variables.

Automatic moving in more complex cases is still not possible.
Like `return Foo(some_var);` can't be transformed in something like `return Foo(move(some_var));`.
So, `move` should be still specified manually.


### Conclusion

Adding such easy feature allows to simplify code in many places.
Writing `return move` isn't needed anymore.
Yet another benefit - in some cases it's not longer needed to declare returned variable as mutable.

So, the code like in the beginning of this post now looks like this:


```
var SomeStruct s{ .x= InitX(), .y= InitY() };
return s;
```
