## What kinds of errors Ü can prevent


### General unsoundness errors

Ü compiler obviously detects errors related to the program general unsoundness.
This includes:
* missing imports
* lexical errors
* syntax errors
* redefinition errors
* accessing unknown functions/variables/types


### Type errors

Ü has static strong type system.
So, type errors can be detected during compilation.

```
fn GetX() : u32
{
	return "not_a_number"; // Compilation error - expected integer, got string.
}
```


### Control flow errors

Ü compiler checks if `return` is executed in all control paths.

```
fn Foo( bool b ) : i32
{
	if( b )
	{
		return 66;
	}
} // Compilation error - missing "return".
```

It's checked that `break` and `continue` operators are located only within loops and that labels for labeled `break` and `continue` operators are correct.

```
fn Foo()
{
	continue; // Compilation error - "continue" outside loop.
}
```

It's also checked that there is no conditional variable moving.

```
fn Foo( bool b, i32 mut x )
{
	if( b )
	{
		move(x);
	} // Compilation error - variable "x" is moved conditionally.
}
```


### Immutability violation

Ü compiler prevents modifying variables/references marked as `imut`.

```
fn Foo( i32& x )
{
	++x; // Error, modifying a variable using immutable reference.
}

fn Bar( i32& x )
{
	var i32 &mut r= x; // Error, creating a mutable reference for immutable reference.
}
```


### Access rights violation

Ü allows to make some fields of classes `private`.
Accessing these fields outside the class isn't allowed.

```
class C
{
private:
	i32 x_;
}

fn Foo( C& c ) : i32
{
	return c.x_; // Compilation error - accessing private class field outside this class.
}
```

### Accessing moved variables

`move` operator in Ü basically ends lifetime for variable specified.
So, accessing it is an error and such errors are detected.

```
fn Foo( ust::string8 mut s )
{
	auto s_move= move(s);
	s += "a"; // Compilation error - trying to access and modify moved variable.
}
```


### Inheritance rules violation

Ü inheritance model allows for a class to have only one base class, but implement unlimited number of interfaces.
If there is more than one base class, a compilation error is generated.

```
class A polymorph {}
class B polymorph {}
class C : A, B {} // Compilation error - "A" and "B" are both non-interfaces and thus are considered as base classes.
```


### Preventing unsafe operations outside unsafe blocks and expressions

Ü has `unsafe` blocks and expressions - for doing dangerous stuff.
Doing dangerous stuff outside such blocks and expressions isn't allowed.

```
fn Foo( $(i32) x )
{
	var i32 x_loaded= $>(x); // Compilation error - dereferencing raw pointer outside unsafe block.
	Bar(); // Compilation error - calling unsafe function outside unsafe block.
}

fn Bar() unsafe;
```

### Preventing using a variable after its lifetime ends

Ü compiler ensures that no variable can be accessed after its lifetime ended.

```
import "/optional_ref.u"

fn Foo() : i32&
{
	var i32 x= 0;
	return x; // Compilation error - destroyed variable "x" still has references.
}

fn Bar()
{
	var ust::optional_ref_imut</i32/> mut ref;
	{
		var i32 x= 0;
		ref.reset(x); // Save reference to "x" inside "ref".
	} // Compilation error - destroyed variable "x" still has references.
	auto x_val= ref.try_deref(); // Without error generated above this code can access destroyed variable "x".
}
```

### Preventing use-after-free errors

Ü reference checking mechanism can statically prevent using heap memory after it was freed.

```
import "/vector.u"

fn Foo()
{
	var ust::vector</i32/> mut v;
	v.push_back(24);
	auto& first= v.front(); // Hold a reference to first element of the vector, which is heap-allocated.
	v.push_back(42); // Compilation error - modifying variable "v" while a derived reference to it exists.
	// Without such error it's possible that "push_back" method realoccates internal storage and invalidates "first" reference.
}
```


### Preventing unsynchronized mutation from different threads

Ü reference checking mechanism allows to prevent data access synchronization errors - while two or more threads can modify the same variable without synchronization.

```
import "../source/ustlib/imports/thread.u"

fn Foo()
{
	var i32 mut x= 0;

	// This thread class instance holds a mutable reference to "x".
	auto thread= ust::make_thread( lambda[&]() { x*= 2; } );
	x-= 3; // Compilation error - modifying variable "x", which has mutable references to it.
}
```


### Virtual method errors

Ü compiler ensures that a non-abstract class has implementations for all its virtual methods.
It also ensures that no `final` virtual methods are overridden.

```
class A interface
{
	fn virtual pure Foo( this );
}

class B : A // Compilation error - class still contains non-implemented virtual methods.
{
}

class C polymorph
{
	fn virtual Bar( this );
}

class D : C
{
	fn virtual final Bar( this );
}

class E : D
{
	fn virtual override Bar( this ); // Compilation error - overriding "final" method.
}
```

### Unused names

Ü compiler also prevents leaving unused names.
It's done in order to prevent some common mistakes and encourage old code removal.

```
fn Foo( i32 x ) // Compilation error - argument "x" is unused.
{
	var i32 y= 0; // Compilation error - variable "y" is unused.
}
```


## What kinds of errors Ü can't prevent

### Logical errors

It's impossible to detect a logical error - a mismatch between what some piece of code should do and how it was programmed.

```
fn GetFour() : i32
{
	return 7;
}
```

### Halting the program


### Integer division by zero

### Messing with unsafe code

### Messing with foreign code

### Memory leaks via shared pointers
