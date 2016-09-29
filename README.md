# KeywordDispatch

## Introduction

Provides the ability to dispatch functions on different sets of keyword arguments. For example, consider the function of calculating the volumes
of different shapes: cuboid, sphere, cylinder. Using keyword dispatch, it can be defined as follows:

```julia
using KeywordDispatch

# Empty function
vol = KeywordDispatchFunction()

# Defining specializers: cuboid
@defkwspec vol [:a :b :c](args) begin
	args[:a] * args[:b] * args[:c]
end

# For sphere
@defkwspec vol [:r] (args) begin
	4/3 * π * args[:r]^3
end

# For cylinder
@defkwspec vol [:r :h] (args) begin
	π * (args[:r]^2) * args[:h]
end
```

Notice the following:

- `KeywordDispatchFunction()` creates an empty (not-specialized) function.
- Macro `@defkwspec` (short for "define keyword specializer") defines a particular specializer.
- `args` is the argument (of type `Dict`) that is passed to a specializer with all the keyword arguments. The access to a particular one is via indexing only.
- body between `begin` and `end` is treated as a function body.

After this definition, `vol` can be invoked as follows:

```julia
# Sphere
vol(r = 3)
# Cuboid
vol(a = 2, b = 3, c = 7)
# Cylinder
vol(r = 3, h = 2)
# Still cylinder: extra argument is ignored
vol(r = 3, h = 2, c = 7)
```

The following applies to functions defined as `KeywordDispatchFunction`s:

- They can only accept keyword arguments.
- They will receive all keyword arguments and not only specializing ones. In the last example, cylinder volume specializer had `:c => 7` in the dictionary.
- Their invocation is slow (at least slower than normal Julia function). To emphasize this fact, it was intntional to make the specializer to receive its arguments as a dictionary.

## Installation

Not available yet in main Julia repository as it needs some polishing. So, the best option for now is to clone this repo into Julia's modules location. From there, simple `use KeywordDispatch` will work. Tests can be run with `Pkg.test("KeywordDispatch")`.

## Short documentation

Type constructor `KeywordDispatchFunction()` creates a new keyword-generic function.

Function `add_specializer!(newspec, dispatch_function, keys)` adds a new specializer to a dispatch function. `newspec` must be a function of one argument (`Dict{Symbol, Any}`).

Function `remove_specializer!(dispatch_function, keys)` removes an existing specializer from the dispatch function.

Macro `@defkwspec` provides an easy way to add new specializers. It's general form:

```julia
@defkwspec <dispatch_function> [<keys (symbols)>] (<var-name>) begin
	<body with <var-name> being a Dict with all keyword arguments>
end
```

Function invocation can lead to two types of errors if a specializer not found: `KeywordDispatchFunctionNotImplemented` or `KeywordDispathFunctionNotFound` (both are subtypes of `KeywordDispatchError`). In general, it is a bit ambigious which error will be thrown, as it will depend on the history of adding and removing specializers.
