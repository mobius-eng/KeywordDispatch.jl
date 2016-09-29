using KeywordDispatch
using Base.Test

# write your own tests here

add = KeywordDispatchFunction()
# Empty: throws an error "not found"
@test_throws KeywordDispathFunctionNotFound add(x = 2, y = 3)

# Add specializer for x & y
@defkwspec add [:x :y] (args) begin
	args[:x] + args[:y]
end

# Throws unimplemented for x = 2
@test_throws KeywordDispatchFunctionNotImplemented add(x = 2)

@test add(x = 2, y = 3) == 5

@defkwspec add [:x] (args) begin
	args[:x]
end

@test add(x = 2) == 2
@test add(x = 2, z = 7) == 2
@test add(x = 2, y = 3) == 5

remove_specializer!(add, [:x, :y])

@test add(x = 2) == 2
@test_throws KeywordDispatchFunctionNotImplemented add(x = 2, y = 3)
@test add(x = 2, z = 3) == 2
