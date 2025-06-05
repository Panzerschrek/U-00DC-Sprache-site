## What kinds of errors Ü can prevent

Ü is designed to prevent many common programming errors and mistakes, which are typical for some other languages.
Many problems, which cause runtime errors, may be caught in compilation time.
Here are listed some of such errors.


### General unsoundness errors

Ü compiler obviously detects errors related to the program general unsoundness.
This includes:
* missing imports
* import loops
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
	return "not_a_number"; // Compilation error - expected integer, got char array.
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
class C : A, B {} // Compilation error - "A" and "B" are both non-interfaces and thus are considered to be base classes.
```


### Unsafe operations outside unsafe blocks and expressions

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


### Using a variable after its lifetime ends

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

### Use-after-free errors

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


### Unsynchronized mutation from different threads

Ü reference checking mechanism allows to prevent data access synchronization errors - when two or more threads can modify the same variable without synchronization.

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

Ü compiler also prevents having unused names - variables, types, functions, etc.
It's done in order to prevent some common mistakes and encourage old code removal.

```
fn Foo( i32 x ) // Compilation error - argument "x" is unused.
{
	var i32 y= 0; // Compilation error - variable "y" is unused.
}
```


## What kinds of errors Ü can't prevent

Even in such language like Ü it's impossible to prevent all kinds of errors during compilation.
Ü isn't powerfull enough to detect them.
Doing so is impossible in a language with rich possibilities like Ü without adding to much constrains.
Here are listed some mistakes which still may happen in Ü programs.


### Logical errors

It's impossible to detect a logical error - a mismatch between what some piece of code should do and how it was programmed.

```
fn GetFour() : i32
{
	return 7;
}
```


### Halting the program

Ü has `halt` operator for abnormal program termination.
Nothing prevents one to use it to cause such termination or trigger some code, which causes such termination.
It's not considered to be a problem, since such termination happens in a controlled manner, compared to undefined behavior and program state corruption typical for languages like C++.

```
fn Read( [ i32, 4 ]& arr, size_type i ) : i32
{
	return arr[i]; // This compiles without error, but runtime index check is inserted by the compiler.
}

fn Foo()
{
	var [ i32, 4 ] arr= zero_init;
	auto x= Read( arr, 6s ); // This leads to "halt", since it causes out of bounds array access.
}

fn Bar( bool b )
{
	halt if( b ); // "halt" is conditionally triggered.
}

fn Baz()
{
	var ust::optional_ref_imut</f32/> ref;
	auto val= ref.try_deref(); // "halt" is triggered while trying accessing empty "optional_ref".
}
```


### Integer division by zero

Integer division by zero isn't handled specially in Ü.
If it happens, usual OS behavior for such cases is executed, which likely leads to program crash.

So, it should be ensured by the programmer, that no integer division by zero happens.
This also includes other integer division errors, like dividing minimum signed integer value by -1.


### Messing with unsafe code

Nothing prevents one to write incorrect `unsafe`code.
So, it's possible to cause a crash or some other sort of undefined behavior by misusing `unsafe`.

```
fn Foo() : i32
{
	var $(i32) ptr= zero_init;
	unsafe
	{
		return $>(ptr); // This code will likely crash in runtime due to null pointer dereference.
	}
}
```


### Messing with foreign code

Ü allows to call functions from other languages, like C.
It's generally not safe and can cause problems, if foreign functionjs aren't used correctly.

```
fn Foo()
{
	auto mut s= "foo";
	// Undefined behavior - "strlen" C function expects a pointer to a null-terminated string, but strings in Ü aren't null-terminated by-default.
	auto len= unsafe( strlen( $<(s[0]) ) );
}

fn nomangle strlen( $(char8) ptr ) unsafe;
```


### Memory leaks via shared pointers

Shared pointer library classes in Ü use reference counting to detect when it's necessary to destroy and free stored value.
But it's possible to create a cycle with such pointers, which will be never freed, unless someone breaks this cycle manually.

```
import "/shared_ptr.u"

struct Node
{
	i32 payload= 0;
	ust::shared_ptr_nullable_mut</Node/> next;
}

fn Foo()
{
	auto node_ptr= ust::make_shared_ptr( Node{} );
	with( mut lock : node_ptr.lock_mut() )
	{
		lock.deref().next= node_ptr;
	}
	// "node_ptr" now holds a shared pointer to itself, creating simple references cycle.
}
```


### Deadlocks

It's generally impossible to prevent deadlocks in compilation time, especially for such language like Ü, where it's possible to call foreign code and various OS functions.
So, one can easily create a deadlock.

```
import "/shared_ptr_mt.u"

fn Foo()
{
	// "shared_ptr_mt" class contains a "rwlock" primitive to implement safe multithreaded mutation.
	auto ptr= ust::make_shared_ptr_mt( 66 );
	// Take a read lock.
	auto lock0= ptr.lock_imut();
	// Take another lock - mutable, while a read lock still exists.
	// In such case a thread, which needs a mutable lock, waits until other threads have no locks.
	// But in this case it will wait forever, since current thread also has a read lock.
	auto lock1= ptr.lock_mut();
}

```
