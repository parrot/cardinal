require 'Test'
include Test
plan 18

a = [1,2,3,4,5]

is a.values_at(), [], 'values_at (empty)'

is a.values_at(0), [1], 'values_at (scalar 1)'
is a.values_at(4), [5], 'values_at (scalar 2)'
is a.values_at(5), [nil], 'values_at (scalar, over end)'

is a.values_at(-1), [5], 'values_at (from end)'
is a.values_at(-5), [1], 'values_at (from end)'
is a.values_at(-6), [nil], 'values_at (negative, over end)'

is a.values_at(0,1), [1,2], 'values_at (slice)'
is a.values_at(4,5), [5,nil], 'values_at (slice with nil)'
is a.values_at(5,6), [nil,nil], 'values_at (slice with two nils)'

is a.values_at(0..4),  [1,2,3,4,5], 'values_at'
is a.values_at(0...4), [1,2,3,4], 'values_at'

is a.values_at(4..5), [5,nil], 'values_at'
is a.values_at(5..4), [], 'values_at'

is a.values_at(-5..-1), [1,2,3,4,5], 'values_at'
# TODO: verify correct:
is a.values_at(-5...0), [], 'values_at'

# from rubyspec /core/array/values_at_spec.rb
b=a.values_at(1..-2, 1...-2, -2..1)
is b, [2, 3, 4, 2, 3], 'values_at'

b = a.values_at(1, 0, 5, -1, -8, 10)
is b, [2, 1, nil, 5, nil, nil], 'values_at'

