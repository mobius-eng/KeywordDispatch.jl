__precompile__()
module KeywordDispatch

export KeywordDispatchFunction
export KeywordDispathFunctionNotFound
export KeywordDispatchFunctionNotImplemented
export add_specializer!, remove_specializer!
export @defkwspec


"""
Data structure for a function specializing on keywrod arguments.

Field `specializers` is a dictionary with keys being (highest priority)
keyword arguments and every entry of the form

    (function, dict)

where `function` is a function to be called for current specialization and
`dict` provides further specializations on lower priority keyword arguments
"""
type KeywordDispatchFunction
	specializers :: Dict
	KeywordDispatchFunction() = new(Dict())
end

"""
`KeywordDispatchFunction` is funcallable (functor) object that accepts
keyword arguments only
"""
function (d :: KeywordDispatchFunction)(; kwargs...)
    dks = Dict(kwargs)
	find_function(dks, d.specializers, notfound(d, collect(keys(dks))))
end

"""
General error
"""
abstract KeywordDispatchError <: Exception

"""
Error to be thrown if specializers are not found
"""
type KeywordDispathFunctionNotFound <: KeywordDispatchError
    kwdfunction :: KeywordDispatchFunction
    keywords :: Vector{Symbol}
end

function Base.showerror(io :: IO, e :: KeywordDispathFunctionNotFound)
    println(io, "Keywords ", e.keywords,
        " a not found in specializers of ", e.kwdfunction)
end

"""
Error to be thrown if the function is requested with
incomplete list of specializers
"""
type KeywordDispatchFunctionNotImplemented <: KeywordDispatchError
    kwdfunction :: KeywordDispatchFunction
    keywords :: Vector{Symbol}
end

function Base.showerror(io :: IO, e :: KeywordDispatchFunctionNotImplemented)
    println(io,
        "Incomplete keywords specializers ", e.keywords,
        " for ", e.kwdfunction)
end

"""
Function of one argument throwing an error if specializer is not found.
It is used a placeholder when searching for an effective function
"""
function notfound(f, keys)
    x -> throw(KeywordDispathFunctionNotFound(f, keys))
end

function notimplemented(f, keys)
    x -> throw(KeywordDispatchFunctionNotImplemented(f, keys))
end

"""
Finds function applicable to `args` in `dict` which has a form of
`specializers` field of `KeywordDispatchFunction` **and** applies it
to `args`
"""
function find_function(args, dict, default)
	for key in keys(dict)
		if haskey(args, key)
			subdefault, subdict = dict[key]
			return find_function(args, subdict, subdefault)
		end
	end
	default(args)
end

"""
Adds specialized function to a keyword generic function.

- `f` is a new specialized function
- `dispatch` is a `KeywordDispatchFunction` generic function
- `ks` is a sequence of symbols to specialize `dispatch` on. Note
  that the order of symbols matter: they must be ordered from higher priority
  to lower priority
"""
function add_specializer!(f, dispatch :: KeywordDispatchFunction, ks)
    n = length(ks)
    dict = dispatch.specializers
    # Loop over all but last keys:
    # just walking down the dictionary and putting new things on the way
    for i in 1:n-1
        if !haskey(dict, ks[i])
            # No entry: create a placeholder
            ff = notimplemented(dispatch, ks[1:i])
            dict[ks[i]] = (ff, Dict())
        end
        # Simply go down
        default, dict = dict[ks[i]]
    end
    # By now, `dict` is the last dictionary in the structure
    if !haskey(dict, ks[n])
        # no further entries: just create a new one
        dict[ks[n]] = (f, Dict())
    else
        # there is an entry: put new function, keep sub-dictionary
        default, subdict = dict[ks[n]]
        dict[ks[n]] = (f, subdict)
    end
	dispatch
end

"""
Removes a specializer defined by the sequence of keys `ks` from
the keyword-dispatch function `dispatch`.
If the specializer with required keys is not found, the warning is issued
"""
function remove_specializer!(dispatch :: KeywordDispatchFunction, ks)
    n = length(ks)
    dict = dispatch.specializers
    for i in 1:(n-1)
        if !haskey(dict, ks[i])
            warn("remove_specializer!: Specializer for keys ",
                ks[1:i], " not found")
            return dispatch
        end
        f, dict = dict[ks[i]]
    end
    if !haskey(dict, ks[n])
        warn("remove_specializer!: Specializer for keys ",
            ks[1:i], " not found")
        return dispatch
    end
    f, subdict = dict[ks[n]]
    dict[ks[n]] = (notimplemented(dispatch, ks), subdict)
    dispatch
end

"""
Defines new keyword specialization of the keyword-generic function `name`
"""
macro defkwspec(name, kw, args, body)
	return quote
		let f = $(esc(args)) -> ($(esc(body)))
		    add_specializer!(f, $(esc(name)), $(esc(kw)))
        end
    end
end



# find_function(Dict(:x=>2, :y=> 3), add.specializers)

# Example
# add = KeywordDispatchFunction()
# macroexpand(:(@defkwspec add [:x :y] (xx) xx[:x] + xx[:y]))
#
# ff = (:x, :y)
#
# macro foo(x)
#     return quote
#         f() = $(esc(x))
#     end
# end
#
# macroexpand(:(@foo (z,w)))


# add_specializer(args -> args[:x], add, [:x])
# add(x = 2, y = 3)
# @defkwspec add [:x :y] args begin
# 	println("Yay!")
# 	args[:x] + args[:y]
# end

end # module
