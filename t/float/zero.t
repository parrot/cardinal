require 'Test'
include Test

plan 2

a = 0.0
is a.zero?, true

b = 1.0
is b.zero?, false
