---
title:  Async functions
---

Recently i added async functions support in Ü.
In this article i want do describe how i did it and how async functions in Ü work.


### Previous work

Async functions implementation is based on the coroutine support code, which was added into the compiler earlier, while introducing generators in the language.
(Article)[https://habr.com/ru/articles/733088/] about generators in Ü (russian).

Ü compiler uses [coroutines support code](https://releases.llvm.org/15.0.0/docs/Coroutines.html) from the LLVM library.
Switch-resume lowering is used.

Coroutines in Ü are stackless.
Each coroutine function call (async function or generator) creates an object which stores all its state inside - arguments, local variables, temporaries, etc.
Memory for this object is allocated from the heap.
But this allocation may be optimized sometimes by coroutine LLVM passes.
A coroutine object is used to resume coroutine execution and obtain its result.

The compiler generates internal types for coroutine objects, which are class types.
Uniqueness of a coroutine type is determined by the coroutine kind, return type and modifiers, return reference notation, internal reference tags, non_sync tag.
Two coroutine functions may return a coroutine object of the same type, if all these properties are the same.

Ü has operator `yield` to pause coroutines execution.
There is an operator `if_coro_advance`, which resumes coroutine execution and may return its result.


### Changes made for async functions

Async functions are one kind of coroutines.
They can pause their execution and resume it later (as any other coroutine).
When they finish execution, they produce single result, unlike generators, which produce a result after each pause.

In order to implement async functions, some code must be changed.

First `async` keyword was introduced to declare async functions and async function types.
It's used in the same way as the `generator` keyword may be previously used.

Than `async` coroutine kind was added into the compiler.
Some later changes were made for supporting of async functions.

`return` operator code was changed to support `return` for async functions.
It works similar to regular `return`, but it fills a promise value, instead of filling `s_ret` value or returning a value directly via `ret` IR instruction.

`if_coro_advance` operator was changed for async functions support.
The change is minor.
For generators control flow passed to a specified block if generator is not finished.
For async functions control flow passed if an async function is finished, which happens only once.

`yield` operator was also adopted.
For async functions it's possible to use this operator to pause execution without returning a value.

All these changes were made relatively quickly, because (as it was mentioned earlier) a lot of coroutine support code was already there.
After these changes it was technically possible to use async functions.


### Await operator

After changes described above it was still a little bit tricky to use async functions.

Assume the following example: function _Fun1_ simple calls another async function _Fun0_ and returns its result multiplied by two.
Such code looks like this:

```
fn async Fun0() : i32;

fn async Fun1() : i32
{
    auto mut f= Fun0();
    // Resume "f" execution in a loop, until it is not done.
    // If it is not done yet, use "yield" to pause this function execution.
    loop
    {
        if_coro_advance( r : f )
        {
            return r * 2;
        }
        yield;
    }
}
```

This code contains a lot of boilerplate comparing to analogous code with non-async (regular) functions:

```
fn Fun0() : i32;

fn Fun1() : i32
{
   return Fun0() * 2;
}
```

In order to reduce such boilerplate i decided to add an operator, that does basically the same as the code in the first example.
This is the `await` operator.

This operator looks like member access operator - it is postfix, starts with `.` and has following `await` keyword.
Internally it works like this: it creates a loop, in which it resumes passed async function object execution until it is done.
If it is not done yet - it pauses execution of the caller function.
When passed async function finishes, its result is extracted and returned as `await` operator result.

Now an example above may be rewritten like this:

```
fn async Fun0() : i32;

fn async Fun1() : i32
{
    return Fun0().await * 2;
}
```

Basically `await` operator is just a glue for calling of async function within an other async function.

However internal implementation of this operator was not so easy, as just adding a loop with `resume` and `yield` inside.
This operator may pause the caller function execution in an arbitrary place inside any expression.
And it's allowed to destroy async function object when it is paused.
For such destruction the compiler generates destructors call code for each pause point.

Until recently there were some places where such destructors call was not possible.
Consider this example:

```
class A
{
public:
    fn constructor( i32 x );
    fn destructor();

    fn GetX(this) : i32;

private:
    i32 x_;
}

struct B
{
    A x;
    A y;
    A z;

    fn destructor();
}

fn async Fun0() : i32;

fn async Fun1() : i32
{
    var B b{ .x(42), .y( Fun0().await ), .z( 24 ) };
    return b.x.GetX() * b.y.GetX() * b.z.GetX();
}

```

What happens, if after `await` for _Fun0_ call inside `b` variable initializer _Fun1_ coroutine object is destroyed?
In such cases destructors for already constructed objects should be called.
But the compiler had no such possibility.
Before `await` operator introduction it called no destructors for `b` variable or its parts before `b` constructor finishes.

In order to fix this i improved destructors calling code.
Now in example above destructors for already constructed members of `b` are called - for `x`, but not for `y` and `z`.
Destructor of `b` itself is also not called.
Same changes were made in other similar places - for sequence initializers, for function calls.


### Inlining optimization

`await` operator significantly simplifies async functions usage.
However, i found another problem, that makes async functions not so great comparing to regular functions.

As it was mentioned above, Ü compiler uses switch-lowering for coroutines.
This means, that each coroutine object has a hidden field with current resume point index.
When resuming a coroutine, `switch` IR instruction is used to pass control flow to the basic block corresponding to current coroutine state.

For async functions it's common to have deep call stacks.
Assume now, that an async function with deep 10 wants to yield.
It does so, its caller with depth 9 does also `yield` in `await` operator, and its caller with depth 8 does also so, etc., until the start of the async call stack.
Now when a root coroutine needs to be resumed, this call stack must be traversed again, with `switch` for each async function in the stack.

Such chain of switches makes work with async functions non-optimal, it contains a lot of switches instead of single jump instruction, as it may be in the optimal case.
Each `switch` increases code size and is unfriendly for the CPU branch predictor.

Additionally deep call stacks of async functions are optimized poorly by the LLVM optimization passes.
It's common to replace heap allocations with stack allocations for coroutine state if an async function usage was inlined.
But LLVM still fails to optimize-out internal coroutine variables for inlined async functions - like destroy/resume function pointers, intermediate promises, etc.
This all increases overall memory block size for the root async function state.

In order to solve such problems i decided to implement my own inlining - specially for async calls.

The compiler frontend code marks specially coroutine-related instructions and `await` operator-related instructions.
Later the inlining optimization code searches for these instructions to find places with `await` calls.
Than it performs force-inlining for such calls.

All coroutine state-related code of an inlined function is removed.
_llvm.coro.suspend_ of an inlined function is replaced with _llvm.coro.suspend_ of the destination function, it is fine, since `await` operator does exactly this.
Promise value of an inlined function is directly used instead of calling _llvm.coro.promise_ for an inlined coroutine object.
Jumps to _coro_cleanup_ blocks of an inlined function are replaced with jumps to destroy block of an `await` operator of the destination function, in order to call destructors of an inlined function properly.
Jumps to _coro_suspend_final_ are replaced with jump to _await_done_ block.
Await loop is removed entirely.
Also any instructions related to the original coroutine object of an inlined function are removed.
Allocations blocks of an inlined function are prepended to the allocation blocks of the destination function.

The inlining process described above deals fine with async calls forming acyclic graph.
For most cases it is fine.
But inlining code still may handle cases with recursive async calls, however the result of such inlining may be suboptimal.

There are of course some disadvantages of such force-inlining.
Inlining may increase code size if async functions contain a lot of code that does something non-trivial rather than calling other async and non-async functons.

But it seems like benefits are greater than disadvantages.
Especially it works great for cases, where an async function contains just single `await` call to another async function with some args preparation and result processing.
Another common case - with several sequential `await` calls, also works good.

An example of inlining:

Source code:
```
fn async Mul34( i32 x ) : i32
{
	yield;
	return x * 34;
}

fn async nomangle Mul34Add5( i32 x ) : i32
{
	return Mul34(x).await + 5;
}
```

IR code without inlining (O2):
```
define internal fastcc void @Mul34Add5.resume(ptr noalias nocapture nonnull align 8 dereferenceable(64) %coro_handle) #0 {
resume.entry:
  %.reload.addr = getelementptr inbounds %Mul34Add5.Frame, ptr %coro_handle, i64 0, i32 4
  %coro_promise.reload.addr = getelementptr inbounds %Mul34Add5.Frame, ptr %coro_handle, i64 0, i32 2
  %index.addr = getelementptr inbounds %Mul34Add5.Frame, ptr %coro_handle, i64 0, i32 5
  %index = load i2, ptr %index.addr, align 8
  %switch = icmp eq i2 %index, 0
  br i1 %switch, label %await_loop.thread, label %await_loop

CoroEnd:                                          ; preds = %AfterCoroSuspend13, %AfterCoroSuspend10.thread
  ret void

await_loop.thread:                                ; preds = %resume.entry
  %x.reload.addr = getelementptr inbounds %Mul34Add5.Frame, ptr %coro_handle, i64 0, i32 3
  %x.reload = load i32, ptr %x.reload.addr, align 4
  store ptr @_Z5Mul34i.resume, ptr %.reload.addr, align 8
  %destroy.addr.i = getelementptr inbounds %Mul34Add5.Frame, ptr %coro_handle, i64 0, i32 4, i64 8
  store ptr @_Z5Mul34i.cleanup, ptr %destroy.addr.i, align 8
  %x.spill.addr.i = getelementptr inbounds %Mul34Add5.Frame, ptr %coro_handle, i64 0, i32 4, i64 20
  store i32 %x.reload, ptr %x.spill.addr.i, align 4
  br label %_Z5Mul34i.resume.exit

await_loop:                                       ; preds = %resume.entry
  %index.addr.i.phi.trans.insert = getelementptr inbounds %Mul34Add5.Frame, ptr %coro_handle, i64 0, i32 4, i64 24
  %index.i.pre = load i2, ptr %index.addr.i.phi.trans.insert, align 8, !alias.scope !8
  %phi.cmp = icmp eq i2 %index.i.pre, 0
  br i1 %phi.cmp, label %_Z5Mul34i.resume.exit, label %_Z5Mul34i.resume.exit.thread

_Z5Mul34i.resume.exit.thread:                     ; preds = %await_loop
  %coro_promise.reload.addr.i = getelementptr inbounds %Mul34Add5.Frame, ptr %coro_handle, i64 0, i32 4, i64 16
  %x.reload.addr.i = getelementptr inbounds %Mul34Add5.Frame, ptr %coro_handle, i64 0, i32 4, i64 20
  %x.reload.i = load i32, ptr %x.reload.addr.i, align 4, !alias.scope !8
  %"*.i" = mul i32 %x.reload.i, 34
  store i32 %"*.i", ptr %coro_promise.reload.addr.i, align 8, !tbaa !2, !alias.scope !8
  store ptr null, ptr %.reload.addr, align 8, !alias.scope !8
  br label %AfterCoroSuspend13

_Z5Mul34i.resume.exit:                            ; preds = %await_loop.thread, %await_loop
  %index.addr.i = getelementptr inbounds %Mul34Add5.Frame, ptr %coro_handle, i64 0, i32 4, i64 24
  store i2 1, ptr %index.addr.i, align 8, !alias.scope !8
  %.pr = load ptr, ptr %.reload.addr, align 8
  %0 = icmp eq ptr %.pr, null
  br i1 %0, label %_Z5Mul34i.resume.exit.AfterCoroSuspend13_crit_edge, label %AfterCoroSuspend10.thread

_Z5Mul34i.resume.exit.AfterCoroSuspend13_crit_edge: ; preds = %_Z5Mul34i.resume.exit
  %.phi.trans.insert = getelementptr inbounds %Mul34Add5.Frame, ptr %coro_handle, i64 0, i32 4, i64 16
  %.pre = load i32, ptr %.phi.trans.insert, align 8, !tbaa !2
  br label %AfterCoroSuspend13

AfterCoroSuspend10.thread:                        ; preds = %_Z5Mul34i.resume.exit
  store i2 1, ptr %index.addr, align 8
  br label %CoroEnd

AfterCoroSuspend13:                               ; preds = %_Z5Mul34i.resume.exit.AfterCoroSuspend13_crit_edge, %_Z5Mul34i.resume.exit.thread
  %1 = phi i32 [ %.pre, %_Z5Mul34i.resume.exit.AfterCoroSuspend13_crit_edge ], [ %"*.i", %_Z5Mul34i.resume.exit.thread ]
  %"+" = add i32 %1, 5
  store i32 %"+", ptr %coro_promise.reload.addr, align 8, !tbaa !2
  store ptr null, ptr %coro_handle, align 8
  br label %CoroEnd
}
```

IR code with inlining (O2):
```
define internal fastcc void @Mul34Add5.resume(ptr noalias nocapture nonnull align 8 dereferenceable(32) %coro_handle) #3 {
resume.entry:
  %index.addr = getelementptr inbounds %Mul34Add5.Frame, ptr %coro_handle, i64 0, i32 4
  %index = load i2, ptr %index.addr, align 8
  %switch = icmp eq i2 %index, 0
  br i1 %switch, label %AfterCoroSuspend31.thread, label %AfterCoroSuspend34

CoroEnd:                                          ; preds = %AfterCoroSuspend34, %AfterCoroSuspend31.thread
  ret void

AfterCoroSuspend31.thread:                        ; preds = %resume.entry
  store i2 1, ptr %index.addr, align 8
  br label %CoroEnd

AfterCoroSuspend34:                               ; preds = %resume.entry
  %coro_promise.reload.addr = getelementptr inbounds %Mul34Add5.Frame, ptr %coro_handle, i64 0, i32 2
  %x.reload.addr = getelementptr inbounds %Mul34Add5.Frame, ptr %coro_handle, i64 0, i32 3
  %x.reload = load i32, ptr %x.reload.addr, align 4
  %"*" = mul i32 %x.reload, 34
  %"+" = add i32 %"*", 5
  store i32 %"+", ptr %coro_promise.reload.addr, align 8, !tbaa !2
  store ptr null, ptr %coro_handle, align 8
  br label %CoroEnd
}
```

As it can be seen, the optimization have reduced the memory block size by 32 bytes, unnecessary control flow instructions and load/store instructions were removed.


### Conclusion


Now it's possible to write async code in Ü, much like in another languages with async/await support (like Rust).

However for now there is only language support for async programming.
It's also needed to have async networking/files code and some async functions executor in order to write effective async programs.
Ü standard library provides for now no such functionality.
But technically it possible to write it, the language have all necessary constructions for it.
