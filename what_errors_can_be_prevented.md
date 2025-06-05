## What kinds of errors Ü can prevent


### General unsoundness errors

Ü compiler obviously detects errors related to the program unsoundness.
This includes:
* lexical errors
* syntax errors
* redefinition
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

### Immutability violation

### Access rights violation

### Accessing moved variables

### Inheritance rules violation

### Preventing unsafe operations outside unsafe blocks and expressions

### Virtual method errors

### Unused names


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
