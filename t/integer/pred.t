require 'Test'
include Test
plan 2

a = 1.pred
is a, 0

b = 0.pred
is b, -1

# parse error!
# c = (-1).pred
# is c, (-2)
