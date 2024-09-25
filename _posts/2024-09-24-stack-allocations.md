---
title:  Stack allocations
---

### Motivation

Sometimes it's necessary in a function to create an array with size determined in runtime.
The kifetime of this array should be bounded to scope, where it's declared.
Usually this size is small, but can sometimes require a lot of space, so, allocating a fixed-length storage may not be enough.


### Other languages

Already in old versions of C language there was a built-in function named `alloca`.
This function allocates a memory block on current stack frame.
This allocation is as cheap as possible - it requires only adjasting stack pointer value.
After the function finishes, all allocations made with `alloca` are freed just by restoring stack pointer.

C99 has a better version of this feature.
It allows to declare stack arrays with size determined in runtime (so-calld variable-length arrays).
It works similar to manual usage of `alloca` function, but is slightly better.
Compiler can free allocated memory for such variable-length array when it goes out of scope.
This allows, for example, to use such arrays in loops, which isn't practical with `alloca`.
Sadly this feature isn't implemented in some C compilers, like MSVC.

GCC and Clang allow to use such arrays in C++ too (as language extension).
Constructors and destructors for elements of such arrays are called properly, but only default-constructible types are supported.
But this behavior is non-standatd in C++.


### Elefant in the room

So, if this feature is so usefull, why isn't it a part the modern C++ standards, like C++23?
There are some problems with it.

First, in context of C++ such apprays are very limited because of restricted construction.
There is no easy way to use anything except of default constructor.

Second, such arrays are very error-prone.
They use stack allocation and stack size is usually very limited, like 1MB default size on Windows or 8MB on Linux.
So, it's possible to cause stack overflow and likely crash when usign stack-allocated arrays.

MSVC tries to solve stack overflow problem by introduction of `_malloca` function.
It is similar to `alloca`, but allocates memory from heap for large block sizes (typically 1kb).
But it's not so easy to use as `alloca` - it requires manually calling `_freea` function to free potential heap allocation.

Instead of problems mentioned above some alternative approaches in C++ are used.
The easiest solution is to use `std::vector`, which uses heap allocation and thus is not limited to stack size.
But it isn't fast for small allocations, since heap allocations are usually costly.
A more advanced approach is to use some fixed buffer and heap fallback if it's not enough (like `llvm::SmallVector` does).


### Ü implementation - first approach

I decided to implement support of stack arrays in Ü, but do this wisely.

I found that it's too complicated to perform proper initialization via all possible variants in the compiler itself.
Instead I decided to split this feature into two parts.
First part - a comiler build-in operator for performing raw memory block allocation (and deallocation).
Second part - a library class for owning array over this memory block - with all necessary functionality and proper reference checking.

Initially I implemented `alloca` operator with two parameters - type and size and returning raw pointer to allocated memory block.
This operator was directly translated to `alloca` LLVM instruction.

I decided to add a heap fallback to `alloca` (as `_malloca` in MSVC does), in order to minimize stack overflow risk.
If allocation size is less than limit (currently 4KB), stack allocation is performed, else - heap allocation is used.
With such small size stack overflow is unlikely, since one needs to have simultaniously around 256 4095byte allocations to trigger 1MB stack overflow, which may be possible only in very rare circumstances.
This heap allocation is managed by the Compiler (it knows when to call `free`).

Then I implemented a library helper container class named `array_over_external_memory`.
It's an owned wrapper for a memory block, which is (partially) similar to `ust::vector`, but has size determined at construction and it can't be resized.
Internally it contains just a pointer to memory block and number of elements.
It allows construction of an array of N elements over this block - using default constrctor, filler constructor or an iterator (and wraps unsafe calls).

Lastly I added a macro `scoped_array`, which combines `alloca` operator call and `array_over_external_memory` container instance creation.

After this was done I managed to use `scoped_array` in some places in Ü code.


### Current approach

However the first approach wasn't so great and had some limitations.
It wasn't possible to call `alloca` in a loop, since allocated memory was freed only when function exits and thus using `alloca` in loop may lead to easy stack overflow.

Implementing a heap-allocation fallback for large blocks size was also tricky.
It was necessary to check for a pointer needs to be freed at function and, even if potential `alloca` was conditional.

So, I decided to remove these disadvantages and make this feature much better.

Instead of `alloca` operator I introduced `alloca` declaration - a construction, which performs allocation and declares a raw pointer type variable to hold its result.
Doing so allowed me to track this allocation lifetime - attach it to the surrounding block.
After destructors for variables of a scope blocks were called, allocations made by this `alloca` declaration may be freed too - both for stack allocation and heap fallback.
For stack case i used `llvm.stacsave` and `llvm.stackrestore` instructions to free memory block allocated, which are translated to stack pointer register reading and restoring.

This change allowed me to remove the mentioned above no-allocation-in-loop limitation.
Additionaly result machine code became much cleaner - allocation cleanup code is now executed only where it is necessary.

I updated `scoped_array` macro for usage of the `alloca` declaration instead of `alloca` operator and deleted `alloca` operator code.

### End user experience

Regardles of compiler/standard library complexity for this feature support such (potentially) stack-allocated arrays are easy to use for a programmer.
Examples:
```
	scoped_array i32 mut ints[ GetSize() ]( 0 ); // Declare a mutable scoped array of "i32" elements and fill it with zeros.
```
```
	var ust::vector</ust::string8/> strings;
	scoped_array ust::string_view8 views[ strings.size() ]( strings.iter() ); // Declare an immutable scoped array of "ust::string_view8" elements and intialize it using an iterator.
```

```
	scoped_array ust::string8 mut strings[ 256 ]; // Declare a mutable scoped array of strings, using default constructor.
```

### Conclusion

I managed to use `scoped_array` macro in many places in Compiler1.
In many cases prior to this `ust::vector` was used, which was wastefull because of number of elements was very small (1-10) and memory allocation required by `std::vector` wasn't cheap.
But with `scoped_array` no heap allocation usually happens, which noticeable improves result performance.

Because of heap fallback there is (almost) no stack overflow danger, which is typical for C99 variable-length arrays, which use only stack allocation regardless of array size.

Unfortunately result machine code generated by the LLVM backend is slightly unoptimal.
If at least one dynamic `alloca` instruction is used in a function, LLVM emits stack saving and restoring instructions in the function prologue/epilogue.
This is suboptimal, since `llvm.stacksave` and `llvm.stackrestore` intrinsics are already emited by the Ü compiler fronted, which effectively restore stack size.

For code like this:
```
fn nomangle Foo( size_type s )
{
	alloca i32 ptr[ s ];
	Bar( ptr );
	Baz();
	Baz();
}
fn Bar( $(i32) ptr );
fn Baz();
```
LLVM generates the following assembly (x86-64 target, -O2), with comments added by me:
```asm
Foo:
	pushq	%rbp
	movq	%rsp, %rbp ; Save stack pointer in prologue
	pushq	%r14
	pushq	%rbx
	leaq	(,%rdi,4), %rbx
	cmpq	$4095, %rbx
	ja	.LBB0_2
	; Stack allocation block
	movq	%rdi, %rax
	movq	%rsp, %r14 ; Save stack pointer again via llvm.stacksave
	movq	%rsp, %rdi
	leaq	15(,%rax,4), %rax
	andq	$-16, %rax
	subq	%rax, %rdi
	movq	%rdi, %rsp
	jmp	.LBB0_3
.LBB0_2:
	; Heap allocation block
	movq	%rbx, %rdi
	callq	malloc@PLT
	movq	%rax, %rdi
	movq	%rax, %r14
.LBB0_3:
	; Function body after alloca operator
	callq	_Z3BarPi@PLT
	callq	_Z3Bazv@PLT
	callq	_Z3Bazv@PLT
	cmpq	$4095, %rbx
	ja	.LBB0_5
	; Stack allocation free block
	movq	%r14, %rsp ; Restore stack pointer via llvm.stackrestore
	jmp	.LBB0_6
.LBB0_5:
	; Heap allocated free block
	movq	%r14, %rdi
	callq	free@PLT
.LBB0_6:
	leaq	-16(%rbp), %rsp ; Restore stack pointer in epilogue
	popq	%rbx
	popq	%r14
	popq	%rbp
	retq
```

But even with such slightly suboptimal code (2 more instructions) it's still better to use stack allocations compared to unconditional heap usage.
