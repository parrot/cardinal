require 'Test'
include Test
plan 1

pass '.exit! on Kernel'


Kernel.exit! 0

#should never get here
fail '.exit! on Kernel'
