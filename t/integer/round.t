require 'Test'
include Test

plan 3

a = 1.round
is a, 1

skip 'round with positive ndigit', 'pir'
skip 'round with negative ndigit', 'pir'
