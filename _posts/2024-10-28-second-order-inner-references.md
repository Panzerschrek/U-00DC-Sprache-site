---
title: Second order inner references
---

## Second order inner references

### Motivation

Ü language had long a significant limitation - it wasn't possible to create reference fields to types with references inside.
It wasn't a huge problem - normally reference indirection deeper than one isn't necessary, since types with references inside are usually stuff like ranges/iterators, which can be easily copied.
But sometimes this limitation made things harder.

An example like this didn't worked:

```
// Fine - types with references inside (like ust::string_view8) can be stored inside the vector container.
var ust::vector</ust::string_view8/> mut v;
v.push_back("abc");
v.push_back("defg");
// But this is not fine.
// The "foreach" macro creates an iterator, which itself is a type with references inside.
foreach( &el : v )
{
}
// There is still a workaround - use index-based loop, but it's (sometimes) suboptimal and bulky.
for( auto mut i= 0s; i < v.size(); ++i )
{
	auto& el= v[i];
}
```

Lambdas are also types with possible references inside - if a variable is captured by reference.
So, it wasn't possible to capture by reference variables with references inside.

```
struct S{ i32& x; }
fn Foo( S& s )
{
	auto f0= lambda[&]() : i32
	{
		// "s" is captured by reference.
		// But it's not possible, since it contains reference inside.
		return s.x;
	};
	// A working workaround is to capture "s" by copy.
	auto f1= lambda[=]() : i32
	{
		return s.x;
	};
}
```

Long time I pretended such problems are't significant.
But recently I decided to make at least examples above working.


### Approach

A couple of times I investigated possible approaches to support arbitrary reference indirection depth.
But I came to the conclusion, that such an approach even if is possible, would be too complex.
It makes the language itself too bulky and its compiler too complicated and thus buggy.

So, I decided to find an easier approach, which can at least solve problems mentioned above.
First idea - it's not necessary to support arbitrary reference indirection depth, it's fine to go only one step further - support depth 2 instead of depth 1.
Second idea - limit types of reference fields and allow only single reference tag inside for them - for simplicity.


### Implementation

First I thought changes described above are relatively easy.
Supporting second order inner references requires adding extra compiler work to setup inner references of reference fields when accessing them.
Also it requires some additional checks in functions call code.
Lastly, structs preparation code should be modified.

But in practice it was a little bit more tedious.
There are edge cases in reference notation violation checking - to handle cases where second order reference is returned or linked.
Also I found that it wasn't so easy to support second order references for coroutines and decided (for now) not to support such coroutines.
Lastly, `byval mut` lambdas should be treated a little bit specially, since their fields may be moved.


### Reference notation for second order references

For now I decided (for simplicity) not to add reference notation for naming second order inner references in function signatures.
This limitation doesn't allow to return second order inner references from functions - as a plain reference or as a reference inside the returned value.

The only exception is when a reference to inner reference tag of an argument is returned.
Inner references of this result reference are (for now) assumed to refer to (possible) second order references of the corresponding function argument and its inner tag.
This exception is for now enforced both in call code and in function return references checking code.


### Results

After this change some code is now possible, what wasn't possible before.

It's now fine to use iterator-based iteration for `vector` for an element type with references inside.
The same is for `optional` container - it's possible to create `optional_ref` for it, even if its element type contains references inside.

Lambdas are now sometimes easy to use.
For example, in a couple of places in Compiler1 I needed to specify captured in lambdas variables one-by-one - in order to specify capturing by reference for some variables, and capturing by value of variables with reference inside.
Now this isn't necessary - I can just specify capturing all by reference (`[&]`).

Before:
```
lambda[synt_args, &names_scope, &args, &src_loc]( CodeBuilder &mut self, FunctionContext &mut function_context )
```
After:
```
lambda[&]( CodeBuilder &mut self, FunctionContext &mut function_context )
```

Some code is though still impossible.
Like `vector::from_iterator` method can't be implemented for a contained type with references inside, since returning result of this method requires returning second order reference inside it.
Creating something like `optional_ref` is still impossible for a type with more than one inner reference tag inside, but this limitation may be (sometimes) avoided by creating a wrapper class which collapses inner reference tags into single tag.


### Further improvements

It may be still possible to implement function reference notation for second order references.
But I don't know how to do this properly in order to avoid mistakes and unnecessary complexity.
In case if such notation will be introduced, it will be necessary to rewrite some existing Ü code of containers like `optional_ref` and `random_access_range` in order to specify reference notation for returned reference of data access methods of these containers.

For now I see no necessity to increase reference indirection depth above 2.
Depth 1 works fine for ~95% cases.
Depth 1 and 2 works fine for ~99.5% cases.
I think covering remaining 0.5% cases doesn't worth possible extra language and compiler complexity.
So, it's entirely possible that Ü will never support reference indirection depth more than 2.
