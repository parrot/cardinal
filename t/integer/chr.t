require 'Test'
include Test

plan 4

exclamation = 33.chr
is exclamation, '!'

ua = 65.chr
is ua, 'A'

tilde = 126.chr
is tilde, '~'

# TODO:
#
# * call chr with num over 128
# * call chr with CardinalEncoding
is 1, 0
