require 'Test'
include Test

plan 5

exclamation = 33.chr
is exclamation, '!'

ua = 65.chr
is ua, 'A'

tilde = 126.chr
is tilde, '~'

skip 'chr with internal encoding', 'pir'
skip 'chr with Encoding opt', 'pir'
