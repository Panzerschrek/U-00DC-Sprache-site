---
title:  Reference checking refactoring
---

## Reference checking refactoring

### Introduction

Reference checking in Ü is a mechanism, that statically ensures absence of memory-related errors, like use after free, use after move, data races, etc.
This is one of the most complex parts of Ü.
Internally all reference checks are implemented with usage of graph data structure with nodes (for variables and references) and links between them as edges.
Nodes are also created for logical references inside variables, that may contain references inside.
This functionality worked pretty fine, but had some limitations, that until recently was not so important.


### The problem

Having a single logical node in references graph for all possible references inside a variable was fine.
Until generators were introduced.
Generator is a variable, created by generator-function.
It stores inside references to all reference arguments of called generator-function.
But logically it had only one reference inside.
That created a lot of false-linking while using generators - references obtained as result of generator call had false-positive links to all arguments of a generator, not only necessary ones.

So, for generators single inner reference node limitation was pretty significant.
Even worse it may be not for generators, but for async functions (another kind of coroutines), because async functions must behave as close as possible to regular functions.

For now async functions are not implemented yet.
But single inner reference node limitation seems to be a blocker for async functions implementation.
So, i decided to solve this problem - remove this limitation.


### Solution

Obviously, multiple inner reference nodes must be introduced.
But this task was not so easy.
I performed this works in steps.


#### Inner reference nodes everywhere

First of all, introduction of multiple inner reference nodes requires reworking of reference pollution code.
Earlier reference pollution were implementing by searching a path in the references graph from current node of pollution destination to all variables and creating links to inner reference node of this variable.
But which node to choose, if multiple inner nodes are possible?

I decided to solve this problem by creating inner reference nodes not only for variables, but also for references.
If a reference node has a link to other node (reference or variable), links between corresponding inner reference nodes are also created.
Thus it became possible to trace target inner reference node of pollution destination variable by finding path to it, starting from inner reference node of a reference for which pollution is performed.

Such change had one downside.
Inner reference nodes with corresponding links are now always created when creating a reference to a variable.
This prevents creation of multiple immutable references to variables with mutable references inside.
But in reality this is not a big problem.
Only a couple of synthetic tests were broken because of changes described above.


#### Types with multiple reference nodes inside

How many inner reference nodes has a specific node is determined now by the type of this node.
Each type has 0 or more inner reference tags, for which reference nodes are created.
Fundamental types, enums, raw pointers have 0 reference tags.
Structs/classes may have 0 or more tags.
Tuples have number of tags equal to sum of all tags of element types.

In order to perform proper mapping of logical reference tags to reference fields of structs, special reference notation for fields was introduced.
Reference class field may be annotated with a constant expression in `@()` after reference modifier.
Constant expression is expected to be a `char8` with values in range ["a"; "z"].
Each letter means corresponding tag number ("a" - 0, "b" - 1, "c" - 2, etc.).
Value fields may also have reference notation (specified after field type), if type of this field has references inside.
But type of this notation is different - array of `char8` is expected, since type of the field may have multiple inner reference tags.

The number of total reference tags of the struct is determined by number of used reference tags.
In trivial cases (single reference field or single value field with references inside) reference notation is not required.

When a child node is created for struct value, inner reference nodes of result are linked with corresponding inner reference nodes of source based on this notation.


#### Reworking of function reference notation

Previously it was possible to specify how returned reference of function is linked to arguments by giving special string-based tags to params of the function and to return reference/value.
Also it was possible to specify reference pollution based on these tags.

But such approach had a couple of downsides.
First, such notation was not flexible enough.
Some combinations of return references/reference pollution can not be specified via this notation.
Second, such notation was not compatible with template code.
It was not possible to specify notation based on provided type.

Because of these problems i decided to rework this notation.

New notation is based on constant expressions, specified in `@()` - after parameters list for reference pollution, after return type name for return inner references, after reference modifier for return reference. The format of the notation is different for different parts.

For the reference pollution an array of `[ [ char8, 2 ], 2 ]` elements is expected.
Each element is a pair of destination and source reference description.
Each reference description consists of two chars.
First char - index of function param from "0" up to "9".
Second char - "_" for reference of reference param itself or letters from "a" up to "z" for inner references of the param type.

For the returned references an array of `[ char8, 2 ]` elements is expected - for describing param references, which are returned.
For the returned inner references a tuple of `[ char8, 2 ]` arrays is expected - for describing param references, which are returned for each inner reference tag of returned type.

Such new notation has absolute flexibility - it maps almost 1 to 1 to internal compiler structures for reference notation.
Usage of constant expressions for such notation allows to calculate specific notation in template code based on template arguments.

This notation has a minor downside comparing to previous.
It is a little bit verbose.
In order to reduce this verbosity i added helper code for some common notation cases into standard library.


#### Generators reworking

Introduction of multiple inner reference tags for types allows finally to fix generators and (later) allow to implement async functions.

Now number of inner reference tags of generator variable type is determined based on generator-function params.
Number of tags is sum of number of tags for each its param.
Reference param adds 1 reference tag.
Value param adds number of tags equal to number of tags of the param type.
For now reference params of types with references inside are not supported.

Reference notation for generator-functions may be specified as for any other function and it works as expected.
Only exception - reference pollution is still not supported for generators.

Internal generator types representation was reworked.
Now it contains also return references/return inner references (as any function type), in order to setup proper links for result node of generator call (via `if_coro_advance` operator).


### Conclusion

I spent more than 3 weeks to implement all changes described above.
Before that i spent a lot more time trying to find a way, how to do it.
But now it is finally done.

As it was mentioned before, this refactoring opens a way for async functions implementation.

Also this refactoring opens possibility to remove limitation for reference fields of types with references inside.
I still do not know exactly how to implement it and do not know even whether it is needed.
But i know, that it may be much easier as before.

Another important improvement - now template code may be (sometimes) extended for supporting of types with references inside, which was a big problem earlier.

There are a couple of downsides of the refactoring, of course.
Compiler code is now a little more complex, as before.
And it seems to be a little bit slower.
But i think that this is acceptable to gain such large language improvement in cost of minor compiler slowdown.
