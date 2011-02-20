require 'Test'
include Test
plan 33

a = [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 ]
b = a.slice(1, 4)
is b.size, 4
is b[0], 1
is b[1], 2
is b[2], 3
is b[3], 4

#puts "todo 5" if a.slice(100) == nil

a = [ 1, 2 ]

is a[0],  1,   'array access'
is a[1],  2,   'array access'
is a[2],  nil, 'array access, out of bounds'
is a[-1], 2,   'array access, negative'
is a[-2], 1,   'array access, negative'
is a[-3], nil, 'array access, negative, out of bounds'

is a.slice(0),  1,   'slice single'
is a.slice(1),  2,   'slice single'
is a.slice(2),  nil, 'slice single, out of bounds'
is a.slice(-1), 2,   'slice single, negative'
is a.slice(-2), 1,   'slice single, negative'
is a.slice(-3), nil, 'slice single, negative, out of bounds'

a = [1,2,3,4,5]

is a[1,2], [2,3],      'array access, start+count'
is a[1,0], [],         'array access, start+count, zero count'
is a[1,10], [2,3,4,5], 'array access, start+count, big count'
is a[1,-1], nil,       'array access, start+count, negative count'
is a[10,2], nil,       'array access, start+count, out of bounds start'

is a.slice(1,2),  [2,3],     'slice, start+count'
is a.slice(1,0),  [],        'slice, start+count, zero count'
is a.slice(1,10), [2,3,4,5], 'slice, start+count, big count'
is a.slice(1,-1), nil,       'slice, start+count, negative count'
is a.slice(10,2), nil,       'slice, start+count, out of bounds start'

is a[1..2], [2,3],      'array access, range'
is a[1..10], [2,3,4,5], 'array access, range, big range'
is a[-6..-1], nil,      'array access, range, negative range'

is a.slice(1..2), [2,3],      'slice, range'
is a.slice(1..10), [2,3,4,5], 'slice, range, big range'
is a.slice(-6..-1), nil,      'slice, range, negative range'
