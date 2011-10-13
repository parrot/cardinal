# If this is to test the basic statements then we can't really use Test.rb
# Although of course Test.rb itself contains all the statements tested
puts "1..30"

if 1 then
  puts "ok 1"
else
  puts "not ok 1"
end

unless 0
  puts "not ok 2 # TODO 0 evaluates to false (and so do [] and '') See issue #28"
else
  puts "ok 2"
end

if 0
  puts "ok 3"
else
  puts "not ok 3"
end

unless 0 == 1
  puts "ok 4"
else
  puts "not ok 4"
end

# test empty array

emptyArray = Array.new
unless emptyArray
  puts "not ok 5 # an empty array [] should evaluate to true - Issue 28"
else
  puts "ok 5"
end

if emptyArray
  puts "ok 6"
else
  puts "not ok 6 # an empty array [] should evaluate to true - Issue 28"
end

# test empty string
emptyString = String.new
unless emptyString
  puts "not ok 7 # an empty string '' should evaluate to true - Issue 28"
else
  puts "ok 7"
end

if emptyString
  puts "ok 8"
else
  puts "not ok 8 # an empty string '' should evaluate to true - Issue 28"
end

# the statements enclosed by parentheses '()'
(if 1
  puts "ok 9"
end)

( if 1
  puts "ok 10"
end )

(
  if 1
    puts "ok 11"
  end
)

if (1)
  puts "ok 12"
else
  puts "not ok 13"
end

if (-1)
  puts "ok 14"
else
  puts "not ok 14"
end

# the literals(objects) enclosed by parentheses '()'
(1)
puts "ok 15"

(-1)
puts "ok 16"

# failed
#(- 1)
puts "not ok 17"

# failed
(
-
1
)
puts "ok 18"

# failed
(
-
  1
)
puts "ok 19"

# failed
( - 1 )
puts "ok 20"

(1.0)
puts "ok 21"

([])
puts "ok 22"

# failed
(%W(a b c))
puts "ok 23"

({})
puts "ok 24"

# failed
(//)
puts "ok 25"

("")
puts "ok 26"

# failed
(%Q())
puts "ok 27"

(true)
puts "ok 28"

(false)
puts "ok 29"

(true)
puts "ok 30"

(-1.0)
puts "ok 31"
