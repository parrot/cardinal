require 'Test'
include Test

plan 2

a = 1.0
b = a.eql? 1.0
is b, true

c = 1.0
d = c.eql? 1
is d, false
