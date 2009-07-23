DEBUG = false
CONFIG = {} 
$tests = 0
$test_files = 0
$ok = 0
$nok = 0
$unknown = 0
$failures = 0
$expected_failures = 0
$unexpected_failures = []
$unexpected_passes = 0
$u_p_files = []
$start = Time.now

def parrot(input, output, grammar="", target="")
    target = "--target=#{target}" if target != ""
    sh "#{CONFIG[:parrot]} #{grammar} #{target} -o #{output} #{input}"
end

def make_exe(pbc)
    sh "#{CONFIG[:pbc_to_exe]} cardinal.pbc"
end

def test(file, name="")
    print "Adding #{file} as a test " if DEBUG
    if name == ""
        name = file.gsub(/.t$/,'').gsub(/^[0-9]+-/,'').gsub(/-/,'').gsub(/.*\//,'')
    end
    puts "named #{name}" if DEBUG
    task name => ["cardinal", "Test.pir"] do
        run_test file
    end
end

def run_test(file)
    puts file if DEBUG
    $test_files += 1
    IO.popen("./cardinal t/#{file}", "r") do |t|
        begin 
            plan = t.readline
        rescue EOFError
            plan = "x"
        end
        puts plan if DEBUG
        if plan =~ /^1\.\.([0-9]+)/
            tests = $1.to_i
            $tests += tests
            result = "#{$1} tests... "
            ok = 0
            nok = 0
            unknown = 0
            test = 0
            t.readlines.each do |line|
                test += 1
                puts line if DEBUG
                if line =~ /^ok #{test}/
                    ok += 1
                    if line =~ /TODO/
                        $unexpected_passes += 1
                        $u_p_files += [file]
                    end
                else 
                    if line =~ /^not ok #{test}/
                        nok += 1
                        if line =~ /(TODO|SKIP)/
                            $expected_failures += 1
                        else
                            $unexpected_failures += [file]
                        end
                    else
                        unknown += 1
                    end
                end
            end
            result += "#{ok} ok "
            $ok += ok
            result += "#{nok} not ok"
            $nok += nok
            result += " #{unknown} unknown" if unknown > 0
            $unknown += unknown
            result += " MISSING TESTS" if test < tests
            result += " TOO MANY TESTS" if test > tests
        else
            result = "Complete failure... no plan given"
            $failures += 1
        end
        puts "Running test #{file} #{result}"
    end
end

task :config => "build.yaml" do
    require 'yaml'
    File.open("build.yaml","r") do |f|
        CONFIG.update(YAML.load(f))
    end
    return false unless File.exist?(CONFIG[:parrot])
    return false unless File.exist?(CONFIG[:perl6grammar])
    return false unless File.exist?(CONFIG[:nqp])
    return false unless File.exist?(CONFIG[:pct])
    return false unless File.exist?(CONFIG[:pbc_to_exe])
end

file "build.yaml" do 
    require 'yaml'
    config = {}
    IO.popen("parrot_config build_dir", "r") do |p|
        config[:build_dir] = p.readline.chomp
    end
    puts "Detected parrot_config reports that build_dir is #{config[:build_dir]}."

    config[:parrot] = config[:build_dir] + "/parrot"
    config[:perl6grammar] = config[:build_dir] + "/runtime/parrot/library/PGE/Perl6Grammar.pbc"
    config[:nqp] = config[:build_dir] + "/compilers/nqp/nqp.pbc"
    config[:pct] = config[:build_dir] + "/runtime/parrot/library/PCT.pbc"
    config[:pbc_to_exe] = config[:build_dir] + "/pbc_to_exe"
    File.open("build.yaml","w") do |f|
        YAML.dump(config, f) 
    end
end

file "cardinal" => [:config, "cardinal.pbc"] do
    make_exe("cardinal.pbc")
end

sources = FileList.new('cardinal.pir',
                    'src/parser/quote_expression.pir',
                    'src/gen_grammar.pir',
                    'src/gen_actions.pir',
                    'src/gen_builtins.pir')

file "cardinal.pbc" => sources do
    parrot("cardinal.pir","cardinal.pbc")
end

file "src/gen_grammar.pir" => [:config, 'src/parser/grammar.pg'] do 
    parrot("src/parser/grammar.pg", "src/gen_grammar.pir", CONFIG[:perl6grammar])
end

file "src/gen_actions.pir" => [:config, "src/parser/actions.pm"] do
    parrot("src/parser/actions.pm","src/gen_actions.pir",CONFIG[:nqp],'pir')
end

builtins = FileList.new("src/builtins/guts.pir", "src/builtins/control.pir", "src/builtins/say.pir", "src/builtins/cmp.pir", "src/builtins/op.pir", "src/classes/Object.pir", "src/classes/NilClass.pir", "src/classes/String.pir", "src/classes/Integer.pir", "src/classes/Array.pir", "src/classes/Hash.pir", "src/classes/Any.pir", "src/classes/Range.pir", "src/classes/Bool.pir", "src/classes/Kernel.pir", "src/classes/Time.pir", "src/classes/Math.pir", "src/classes/GC.pir", "src/classes/IO.pir", "src/classes/Proc.pir", "src/classes/File.pir", "src/classes/FileStat.pir", "src/classes/Dir.pir", "src/builtins/globals.pir", "src/builtins/eval.pir", "src/classes/Continuation.pir") 

file "src/gen_builtins.pir" => builtins do
    puts "Generating src/gen_builtins.pir"
    File.open('src/gen_builtins.pir','w') do |f|
        builtins.each do |b|
            f.write(".include \"#{b}\"\n")
        end
    end  
end

file "Test.pir" => ["cardinal.pbc", "Test.rb"] do
    parrot("Test.rb", "Test.pir", "cardinal.pbc", "pir")
end

task :default => ["cardinal", "Test.pir"]

namespace :test do |ns|
    test "00-sanity.t"
    test "01-stmts.t"
    test "02-functions.t"
    test "03-return.t"
    test "04-indexed.t"
    test "05-op-cmp.t"
    test "07-loops.t"
    test "08-class.t"
    test "09-test.t"
    test "10-regex.t"
    test "11-slurpy.t"
    test "12-gather.t"
    test "99-other.t"
    test "alias.t"
    test "assignment.t"
    test "blocks.t"
    test "constants.t"
    test "continuation.t"
    test "freeze.t"
    test "gc.t"
    test "nil.t"
    test "proc.t"
    test "range.t"
    test "splat.t"
    test "time.t"
    test "yield.t"
    test "zip.t"
    
    namespace :array do 
        test "array/array.t"
        test "array/at.t"
        test "array/clear.t"
        test "array/collect.t"
        test "array/compact.t"
        test "array/concat.t"
        test "array/delete.t"
        test "array/empty.t"
        test "array/equals.t"
        test "array/fill.t"
        test "array/first.t"
        test "array/flatten.t"
        test "array/grep.t"
        test "array/include.t"
        test "array/intersection.t"
        test "array/join.t"
        test "array/mathop.t"
        test "array/pop.t"
        test "array/reverse.t"
        test "array/shift.t"
        test "array/slice.t"
        test "array/sort.t"
        test "array/to_s.t"
        test "array/uniq.t"
        test "array/warray.t"

        task :all => [:array, :at, :clear, :collect, :compact, :concat, :delete, :empty, :equals, :fill, :first, :flatten, :grep, :include, :intersection, :join, :mathop, :pop, :reverse, :shift, :slice, :sort, :to_s, :uniq, :warray]
    end
    
    namespace :file do 
        test "file/dir.t"
        test "file/file.t"
        test "file/stat.t" 
        
        task :all => [:dir, :file, :stat]
    end

    namespace :hash do
        test "hash/hash.t"
        test "hash/exists.t"
        
        task :all => [:hash, :exists]
    end
    
    namespace :integer do
        test "integer/integer.t"
        test "integer/times.t"
        test "integer/cmp.t"

        task :all => [:integer, :times, :cmp]
    end

    namespace :kernel do
        test "kernel/exit.t"
        test "kernel/open.t"
        test "kernel/sprintf.t"

        task :all => [:exit, :open, :sprintf]
    end

    namespace :math do
        test "math/functions.t"
        
        task :all => [:functions]
    end
    
    namespace :range do
        test "range/each.t"
        test "range/infix-exclusive.t"
        test "range/infix-inclusive.t"
        test "range/membership-variants.t"
        test "range/new.t"
        test "range/to_a.t"
        test "range/to_s.t"
        test "range/tofrom-variants.t"

        task :all => [:each, :infixexclusive, :infixinclusive, :membershipvariants, :new, :to_a, :to_s, :tofromvariants]
    end 

    namespace :string do
        test "string/add.t"
        test "string/block.t"
        test "string/capitalize.t"
        test "string/chops.t"
        test "string/cmp.t"
        test "string/concat.t"
        test "string/downcase.t"
        test "string/eq.t"
        test "string/mult.t"
        test "string/new.t"
        test "string/quote.t"
        test "string/random_access.t"
        test "string/reverse.t"
        test "string/upcase.t"

        task :all => [:add, :block, :capitalize, :chops, :cmp, :concat, :downcase, :eq, :mult, :new, :quote, :random_access, :reverse, :upcase]
    end

    task :basic => [:sanity, :stmts, :functions, :return, :indexed, :opcmp, :loops, :class, :test, :regex, :slurpy, :gather, :other, :alias, :assignment, :blocks, :constants, :continuation, :freeze, :gc, :nil, :proc, :range, :splat, :time, :yield, :zip]
    task :all => [:basic, "array:all", "file:all", "hash:all", "integer:all", "kernel:all", "math:all", "range:all", "string:all"] do
        dur_seconds = Time.now.to_i - $start.to_i
        dur_minutes = 0
        while dur_seconds > 60
            dur_seconds -= 60
            dur_minutes += 1
        end
        puts "Test statistics:"
        puts " The test suite took #{dur_minutes} minutes and #{dur_seconds} seconds."
        puts " #{$tests} tests were run, from #{$test_files} files."
        puts " #{$ok} tests passed, #{$unexpected_passes} of which were unexpected." 
        unless $u_p_files.empty?
            $u_p_files.uniq!
            puts " Unexpected passes were found in the following files:"
            $u_p_files.each do |pass|
                puts "  #{pass}"
            end
        end
        puts " #{$nok} tests failed, #{$expected_failures} of which were expected."
        unless $unexpected_failures.empty?
            $unexpected_failures.uniq!
            puts " Unexpected failures were found in the following files:"
            $unexpected_failures.each do |fail|
                puts "  #{fail}"
            end
        end
        puts " There were #{$unknown} unknown or confusing results."
        puts " There were #{$failures} complete failures."
        puts " -- CLEAN FOR COMMIT --" if $nok - $expected_failures == 0 and $unknown == 0 and $failures == 0
    end
end
