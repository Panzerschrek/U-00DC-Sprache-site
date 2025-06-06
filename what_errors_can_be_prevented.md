## What kinds of errors Ü can prevent

Ü is designed to prevent many common programming errors and mistakes, which are typical for some other programming languages.
Many problems, which cause runtime errors in these languages, may be caught in compilation time in Ü.
Here are listed some of such errors (but not all of them, obviously).


### General unsoundness errors

Ü compiler obviously detects errors related to the program general structure.
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

fn Foo()
{
	var i32 x= 0;
	var f32 y= x; // Compilation error - conversion between numeric types should be explicit.
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

fn Bar()
{
	loop label one
	{
		break label ane; // Compilation error - label "ane" not found.
	}
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

Trivially-unreachable code is also detected and an error is generated.

```
fn Foo()
{
	return;
	var i32 x= 0; // Compilation error - unreachable code.
}

fn Bar( bool b ) : i32
{
	if( b )
	{
		return 66;
	}
	else
	{
		return 77;
	}
	return 33; // Compilation error - unreachable code.
}
```


### Uninitialized variables

In Ü all variables should be properly initialized.
Fundamental scalars require explicit initialization, classes may have default constructors allowing safe default initialization.
If a variable isn't initialized properly, an error is generated.

```
fn Foo()
{
	var i32 mut x; // Compilation error - expected initializer for variable "x".
}

struct S
{
	f32 f;
}

fn Bar()
{
	var S mut s{}; // Compilation error - expected initializer for field "f".
}
```


### Immutability violation

Ü compiler prevents modifying variables/references marked as `imut`.
It's important to prevent such modification, since mutable/immutable variables separation is an important part of Ü safety mechanisms.

```
fn Foo( i32& x )
{
	++x; // Error, modifying a variable using an immutable reference.
}

fn Bar( i32& x )
{
	var i32 &mut r= x; // Error, creating a mutable reference for an immutable reference.
}
```


### Missing values in switch operator

Ü has `switch` operator, which allows to redirect control flow based on some scalar value.
It's statically checked that the whole range of values is handled.

```
fn Foo( u32 x )
{
	switch(x)
	{
		0u -> {},
		1u -> {},
		2u -> {},
		3u ... 33u -> {},
		// Compilation error - values in range 34 to 4294967295 aren't handled.
	}
}

enum SomeEnum{ A, B, C, D, E, G, H, I }

fn Bar( SomeEnum e )
{
	switch(e)
	{
		SomeEnum::A, SomeEnum::B -> {},
		SomeEnum::C ... SomeEnum::E -> {},
		SomeEnum::I -> {},
		// Compilation error - values in range 5 to 6 (SomeEnum::G to SomeEnum::H) aren't handled.
	}
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

`move` operator in Ü ends lifetime for variable specified.
So, accessing it after moving is an error and such errors are detected.

```
fn Foo( ust::string8 mut s )
{
	auto s_move= move(s);
	s += "a"; // Compilation error - trying to access and modify moved variable.
}
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
	// Without such error it's possible that "push_back" method reallocates internal storage and invalidates "first" reference.
}
```


### Unsynchronized mutation from different threads

Ü reference checking mechanism allows to prevent data access synchronization errors - when two or more threads can modify the same variable without synchronization.

```
import "/thread.u"

fn Foo()
{
	var i32 mut x= 0;

	// This thread class instance holds a mutable reference to "x".
	auto thread= ust::make_thread( lambda[&]() { x*= 2; } );
	x-= 3; // Compilation error - modifying variable "x", which has mutable references to it.
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


### Virtual method errors

Ü compiler ensures that a non-abstract class has implementations for all its virtual methods.
It also ensures that no `final` virtual methods are overridden.

```
class A interface
{
	fn virtual pure Foo( this );
}

class B : A // Compilation error - class still contains unimplemented virtual methods.
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

Even in such safe language like Ü it's impossible to prevent all kinds of errors during compilation.
Ü isn't powerful enough to detect them.
Doing so is impossible in a language with rich possibilities like Ü, without adding too many constrains.
Here are listed some mistakes, which still may happen in Ü programs.


### Logical errors

It's impossible to detect a logical error - a mismatch between what some piece of code should do and how it was programmed.

```
fn GetFour() : i32
{
	return 7; // Obviously seven is not four.
}

fn MultiplyTwoNumbers( u32 x, u32 y ) : u32
{
	return x / y; // It doesn't look like multiplication.
}
```


### Halting the program

Ü has `halt` operator for abnormal program termination.
Nothing prevents one to use it to cause such termination or trigger some code, which causes such termination.
It's not considered to be a problem, since such termination happens in a controlled manner, compared to undefined behavior and program state corruption typical for languages like C++.

```
import "/optional_ref.u"

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

fn Lol()
{
	Bar(true); // Trigger conditional "halt" in function "Bar".
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

```
fn Foo()
{
	auto res= Div( 67u, 0u );
}

fn Div( u32 x, u32 y ) : u32
{
	return x / y; // This code crashes in runtime, if "y" is zero.
}

```


### Messing with unsafe code

Nothing prevents one to write incorrect `unsafe` code.
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
It's generally not safe and can cause problems, if foreign functions aren't used correctly.

```
fn Foo()
{
	auto mut s= "foo";
	// Undefined behavior - "strlen" C function expects a pointer to a null-terminated string, but strings in Ü aren't null-terminated by-default.
	auto len= unsafe( strlen( $<(s[0]) ) );
}

fn nomangle strlen( $(char8) ptr ) unsafe : size_type;
```


### Memory leaks via shared pointers

Shared pointer library classes in Ü use reference counting - in order to detect when it's necessary to destroy and free stored value.
But it's possible to create a cycle with such pointers and members of such cycle will be never freed, unless someone breaks it manually.

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
	// "node_ptr" now holds a shared pointer to itself, creating simple shared pointers cycle.
}
```


### Deadlocks

It's generally impossible to prevent deadlocks in compilation time, especially for such language like Ü, where it's possible to call foreign code and various OS functions.
So, one can easily create a deadlock.

```
import "/shared_ptr_mt.u"

fn Foo()
{
	// "shared_ptr_mt" class contains an instance of "rwlock" primitive to implement safe multithreaded mutation.
	auto ptr= ust::make_shared_ptr_mt( 66 );
	// Take a read lock.
	auto lock0= ptr.lock_imut();
	// Take another lock - mutable, while a read lock still exists.
	// In such case a thread, which needs a mutable lock, waits until other threads have no locks.
	// But in this case it will wait forever, since current thread also holds a read lock.
	auto lock1= ptr.lock_mut();
}

```


### Stack overflow

Ü uses native stack for call frames and local variables.
Native stack is usually very small - around several megabytes in size.
Because of that stack overflow is possible, if an Ü program allocates way too much memory for local variables or if it has deep call stacks.
Usually this happens due to infinite recursion.

```
fn Foo()
{
	// Allocate 64 MB of stack memory, which exceeds typical stack size limits.
	var [ i32, 1s << 24u ] mut arr= zero_init;
	arr[7]= 0;
}

// Calling this function will lead to infinite recursion.
fn Bar( i32 x )
{
	Bar( x * 2 );
	Bar( x * 2 + 1 );
}
```


### Infinite loops

Ü can't generally prevent infinite loops.
It's easily to create one.

```
fn Foo()
{
	// This loop runs forever.
	while( Bar() )
	{}
}

fn Bar() : bool { return true; }

```


### Out of memory

If operating system fails to allocate enough memory for a program written in Ü, this program will be likely terminated.
Ü has no mechanism for handling out-of-memory situations, since doing so isn't generally possible and can make the language too complex.
Other languages like C++ or Java try to throw exceptions if memory allocation fails, but usually this doesn't work well and programs aren't designed to catch and handle such exceptions.

```
import "/string.u"

fn Foo()
{
	// Trying to create a string with 2^56 elements, which is way large compared to total memory size of most modern computers.
	var ust::string8 s( 1s << 56s, 'q' );
}
```
