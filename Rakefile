require 'rake/classic_namespace'
require 'rake/clean'

CLEAN.include('gen_*.pir')
CLEAN.include('*/gen_*.pir')
CLEAN.include('*/*/gen_*.pir')
CLEAN.include('Test.pir')
CLEAN.include('build.yaml')
CLEAN.include('*.c')
CLEAN.include('*.o')
CLEAN.include('report')
CLOBBER.include('cardinal')
CLOBBER.include('*.pbc')
CLOBBER.include('report.tar.gz')
CLOBBER.include(['ctags_opt', 'tags'])

DEBUG = ENV['debug'] || false
ALTERNATIVE_RUBY = ENV['test_with'] || false
PARROT_CONFIG = ENV["PARROT_CONFIG"] || 'parrot_config'
$config = {} 
$location = {
    :parrot => "/parrot",
    :perl6grammar => "/runtime/parrot/library/PGE/Perl6Grammar.pbc",
    :nqp => "/runtime/parrot/library/nqp-rx.pbc",
    :pct => "/runtime/parrot/library/PCT.pbc",
    :pbc_to_exe => "/pbc_to_exe"
}
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
$missing = 0
$missing_files = []
$toomany = 0
$toomany_files = []
$issue_counts = Hash.new(0)
$issue_lacks = 0
$i_l_files = []
$comp_fails = 0
$c_f_files = []
$pl = false
$start = Time.now
$meta = Hash.new
$report = false

def clean?
    return false if $nok > $expected_failures
    return false if $failures > 0
    return false if $unknown > 0
    return false if $missing > 0
    return false if $toomany > 0
    return false if $issue_lacks > 0
    return false if $comp_fails > 0
    return true 
end

def pl(word)
    $pl ? word + "s" : word
end

def were
    $pl ? "were" : "was"
end

def are
    $pl ? "are" : "is"
end

def them
    $pl ? "them" : "it"
end

def parrot(input, output="", grammar="", target="")
    target = "--target=#{target}" if target != ""
    output = "-o #{output}" if output != ""
    puts "Running parrot: #{$config[:parrot]} #{grammar} #{target} #{output} #{input}" if DEBUG
    sh "#{$config[:parrot]} #{grammar} #{target} #{output} #{input}"
end

def make_exe(pbc)
    sh "#{$config[:pbc_to_exe]} cardinal.pbc"
end

def test(file, name="")
    print "Adding #{file} as a test " if DEBUG
    pir_file = file.gsub(/.t$/,'.pir')
    if pir_file =~ /\//
        pir_file.gsub!(/\/([^\/]+)$/) {"/gen_#$1"}
    else
        pir_file = "gen_#{pir_file}"
    end
    if name == ""
        name = file.gsub(/.t$/,'').gsub(/^[0-9]+-/,'').gsub(/-/,'').gsub(/.*\//,'')
    end
    if ALTERNATIVE_RUBY
        task name do
            run_test file
        end
    else
        file "t/#{pir_file}" => [:config, "t/#{file}", "src/gen_actions.pir", "src/gen_grammar.pir"] do
            unless File.exists?('cardinal.pbc')
                Task['cardinal.pbc'].invoke
            end
            begin
                parrot("t/#{file}", "t/#{pir_file}", "cardinal.pbc", "pir")
            rescue RuntimeError
                File.open("t/#{pir_file}",'w') do |f|
                    f.write(".sub main :main\nsay 'FAILED TO COMPILE'\n.end")
                end
            end
        end
        puts "named #{name}" if DEBUG
        task name => [:config, "t/#{pir_file}", "cardinal.pbc", "Test.pir"] do |t|
            run_test pir_file, "#{t.scope.join(':')}:#{name}"
        end
    end
end

def get_report_file(filename)
    dir = "report/t/" + File.dirname(filename)
    dir.gsub!(/\/\./, '')
    mkdir_p(dir)
    ext = File.extname(filename)
    fn = dir + "/" + File.basename(filename, ext)
    fn += ".t"
    fn.gsub!(/gen_/,'')
    f = File.new(fn, 'w')
    $meta['file_order'] += [fn.gsub(/report\//,'')]
    return f
end

def run_test(file,name="")
    puts file if DEBUG
    name = file if name == ""
    $test_files += 1
    command = ALTERNATIVE_RUBY || $config[:parrot]
    report_file = get_report_file(file) if $report
    IO.popen("#{command} t/#{file}", "r") do |t|
        begin 
            plan = t.readline
        rescue EOFError
            plan = "x"
        end
        puts plan if DEBUG
        report_file.write(plan) if $report
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
                report_file.write(line) if $report
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
                            if line =~ /See issue #([0-9]+)/
                                $issue_counts[$1] += 1
                            else
                                puts "Lacks issue." if DEBUG
                                $issue_lacks += 1
                                $i_l_files += [file]
                            end
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
            if test < tests 
                result += " MISSING TESTS"
                $missing += 1
                $missing_files += [file]
            end
            if test > tests
                result += " TOO MANY TESTS"
                $toomany += 1
                $toomany_files += [file]
            end
        else
            if plan =~ /FAILED TO COMPILE/
                result = "Complete failure... failed to compile."
                $comp_fails += 1
                $c_f_files += [file]
            else
                result = "Complete failure... no plan given"
            end
            $failures += 1
        end
        report_file.close if $report
        puts "Running #{name} #{result}"
    end
end

desc "Produce a TAP archive"
task "report.tar.gz" do
    $report = true
    $meta['start_time'] = Time.now.to_i
    $meta['file_order'] = Array.new
    Task['test:all'].invoke
    $meta['stop_time'] = Time.now.to_i
    $meta['extra_properties'] = {
        'Architecture' => get_arch,
        'Platform' => get_platform,
        'Branch' => get_branch,
        'Submitter' => get_submitter,
        'Commit' => get_commit
    }

    IO.popen("#{PARROT_CONFIG} revision", "r") do |p|
        $meta['extra_properties']['Parrot Revision'] = p.readline.chomp.to_i
    end

    require 'yaml'
    File.open('report/meta.yml','w') do |f|
        YAML::dump($meta, f)
    end
    chdir 'report'
    sh 'tar cfz ../report.tar.gz *'
    chdir '..'
end

desc "Submit a smolder report."
task :smolder => "report.tar.gz" do
  puts 'Creating a smolder report. This will take only a few minutes...', ''

  command = 'curl '
  contents = {
    :username => 'parrot-autobot',
    :password => 'qa_rocks',
    :comments => 'Submit a smolder report.',
    :architecture => "#{get_arch}",
    :revision => "#{get_commit}",
    :report_file => '@report.tar.gz'
  }
  url = 'http://smolder.parrot.org/app/projects/process_add_report/10'

  contents.each do |k, v|
    command << %Q(-F "#{k.to_s}=#{v}" )
  end
  command << url
  `#{command} || exit 1`

  if $?.exitstatus == 0
    puts 'Your report sumitted.', 'You can see other recent reports at http://smolder.parrot.org/app/projects/smoke_reports/10'
  else
    puts 'Error occurred. Please contact Cardinal Team.', '#cardinal on irc.parrot.org'
  end
end

desc "Determine configuration information"
task :config => "build.yaml" do
    require 'yaml'
    File.open("build.yaml","r") do |f|
        $config.update(YAML.load(f))
    end

    puts "Configuring..."
    puts "build_dir is #{$config[:build_dir]}"
    err_msg = []

    err_msg << $location[:parrot] unless File.exist?($config[:parrot])
    err_msg << $location[:perl6grammar] unless File.exist?($config[:perl6grammar])
    err_msg << $location[:nqp] unless File.exist?($config[:nqp])
    err_msg << $location[:pct] unless File.exist?($config[:pct])
    err_msg << $location[:pbc_to_exe] unless File.exist?($config[:pbc_to_exe])

    if err_msg.size > 0
      err_msg = err_msg.map {|c| 'build_dir' + c + ' does not exist'}
      abort "aborted!\n" + err_msg.join("\n")
    end
end

def get_arch
    `uname -p`.chomp
end

def get_platform
    `uname -s`.chomp
end

def get_branch
    `git status`.split('\n')[0].split(' ')[3]
end

def get_submitter
    submitter = ENV['SMOLDER_SUBMITTER']
    submitter = "#{`git config --get user.name`} <#{`git config --get user.email`}>" if submitter == ''
    return submitter
end

def get_commit
    `git log -1 --pretty=format:%H`.chomp
end

file "build.yaml" do 
    require 'yaml'
    config = {}
    IO.popen("#{PARROT_CONFIG} build_dir", "r") do |p|
        $config[:build_dir] = p.readline.chomp
    end
    print PARROT_CONFIG == 'parrot_config' ? "Detected " : "Provided "
    puts "parrot_config reports that build_dir is #{$config[:build_dir]}."

    $config[:parrot] = $config[:build_dir] + $location[:parrot]
    $config[:perl6grammar] = $config[:build_dir] + $location[:perl6grammar]
    $config[:nqp] = $config[:build_dir] + $location[:nqp]
    $config[:pct] = $config[:build_dir] + $location[:pct]
    $config[:pbc_to_exe] = $config[:build_dir] + $location[:pbc_to_exe]

    File.open("build.yaml","w") do |f|
        YAML.dump($config, f) 
    end
end

desc "Make the cardinal binary."
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
    parrot("src/parser/grammar.pg", "src/gen_grammar.pir", $config[:perl6grammar])
end

file "src/gen_actions.pir" => [:config, "src/parser/actions.pm"] do
    parrot("src/parser/actions.pm","src/gen_actions.pir",$config[:nqp],'pir')
end

builtins = FileList.new("src/builtins/guts.pir", "src/builtins/control.pir", "src/builtins/say.pir", "src/builtins/cmp.pir", "src/builtins/op.pir", "src/classes/Object.pir", "src/classes/Exception.pir", "src/classes/NilClass.pir", "src/classes/String.pir", "src/classes/Integer.pir", "src/classes/Array.pir", "src/classes/Hash.pir", "src/classes/Range.pir", "src/classes/TrueClass.pir", "src/classes/FalseClass.pir", "src/classes/Kernel.pir", "src/classes/Time.pir", "src/classes/Math.pir", "src/classes/GC.pir", "src/classes/IO.pir", "src/classes/Proc.pir", "src/classes/File.pir", "src/classes/FileStat.pir", "src/classes/Dir.pir", "src/builtins/globals.pir", "src/builtins/eval.pir", "src/classes/Continuation.pir") 

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

def get_ctags
  ctags = `which ctags`.chomp

  # any of exit statuses except 0 are fault
  unless $?.exitstatus == 0
    puts "Exuberant Ctags is needed to generates tags file."
    exit 1
  end

  unless `#{ctags} --version`.scan(/Exuberant Ctags/).size > 0
    puts "You have other version of ctags. Make sure Exuberant Ctags be current ctags instead of your own."
    exit 1
  end

  ctags
end

namespace :tags do
  desc "Generate ctags option file"
  task :gen_option do
    File.open "./ctags_opt", "w" do |f|
      f.write "-f tags\n"
      f.write "-R\n"
      f.write "--totals\n"
      f.write "--exclude=.git\n"
      f.write "--exclude=.gitignore\n"
      f.write "--exclude=*~\n"
      f.write "--exclude=*.swp\n"
      f.write "--exclude=*.rb\n"
      f.write "--langdef=Parrot\n"
      f.write "--langmap=Parrot:+.pir.pg.pasm.pmc\n"
      f.write "--sort=yes\n"
      f.write '--regex-Parrot=/^\.sub[ \t]*\'?(infix:)*([a-zA-Z0-9!#$%&*+,.\/:;<=>?@^_`\{\|\}~\-]+)\'?[ \t]*.*/\2/s,subroutine,subroutines/'
      f.write "\n"
      f.write '--regex-Parrot=/^rule[ \t]*([a-zA-Z0-9_]+)[ \t]*(:\"[a-zA-Z0-9!#$%&*+,.\/:;<=>?@^_`\{\|\}~\-]+\"*)*/\1/r,rule,rules/'
      f.write "\n"
      f.write '--regex-Parrot=/^token[ \t]*([a-zA-Z0-9_]+)[ \t]*(:\"[a-zA-Z0-9!#$%&*+,.\/:;<=>?@^_`\{\|\}~\-]+\"*)*/\1/r,token,tokens/'
    end
    puts "ctags_opt has been created"
  end

  desc "Generate tags for vim"
  task :vim => [:gen_option] do
    ctags = get_ctags
    `#{ctags} --options=ctags_opt .`
    FileUtils.rm_f "./ctags_opt"
  end

  desc "Generate tags for emacs"
  task :emacs => [:gen_option] do
    ctags = get_ctags
    `#{ctags} -e --options=ctags_opt .`
    FileUtils.rm_f "./ctags_opt"
  end
end

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
    test "bool.t"
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
        test "array/assign.t"
        test "array/at.t"
        test "array/clear.t"
        test "array/collect.t"
        test "array/compact.t"
        test "array/concat.t"
        test "array/count.t"
        test "array/delete.t"
        test "array/empty.t"
        test "array/equals.t"
        test "array/fetch.t"
        test "array/fill.t"
        test "array/first.t"
        test "array/flatten.t"
        test "array/grep.t"
        test "array/include.t"
        test "array/index.t"
        test "array/insert.t"
        test "array/intersection.t"
        test "array/join.t"
        test "array/mathop.t"
        test "array/pop.t"
        test "array/push.t"
        test "array/reject.t"
        test "array/replace.t"
        test "array/reverse.t"
        test "array/select.t"
        test "array/shift.t"
        test "array/slice.t"
        test "array/sort.t"
        test "array/to_s.t"
        test "array/uniq.t"
        test "array/values_at.t"
        test "array/warray.t"

        desc "Run tests on Array."
        task :all => [:array, :assign, :at, :clear, :collect, :compact, :concat, :count, :delete, :empty, :equals, :fetch, :fill, :first, :flatten, :grep, :include, :index, :insert, :intersection, :join, :mathop, :pop, :push, :reject, :replace, :reverse, :select, :shift, :slice, :sort, :to_s, :uniq, :values_at, :warray]
    end
    
    namespace :file do 
        test "file/dir.t"
        test "file/file.t"
        test "file/stat.t" 
        
        desc "Run tests on File."
        task :all => [:dir, :file, :stat]
    end

    namespace :hash do
        test "hash/hash.t"
        test "hash/exists.t"
        
        desc "Run tests on Hash."
        task :all => [:hash, :exists]
    end
    
    namespace :integer do
        test "integer/integer.t"
        test "integer/times.t"
        test "integer/cmp.t"

        desc "Run tests on Integer."
        task :all => [:integer, :times, :cmp]
    end

    namespace :kernel do
        test "kernel/exit.t"
        test "kernel/open.t"
        test "kernel/sprintf.t"

        desc "Run tests on Kernel."
        task :all => [:exit, :open, :sprintf]
    end

    namespace :math do
        test "math/functions.t"
        
        desc "Run tests on Math."
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

        desc "Run tests on Range."
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
        test "string/empty.t"
        test "string/eq.t"
        test "string/mult.t"
        test "string/new.t"
        test "string/quote.t"
        test "string/random_access.t"
        test "string/reverse.t"
        test "string/upcase.t"

        desc "Run tests on String."
        task :all => [:add, :block, :capitalize, :chops, :cmp, :concat, :downcase, :empty, :eq, :mult, :new, :quote, :random_access, :reverse, :upcase]
    end

    desc "Run basic tests."
    task :basic => [:sanity, :stmts, :functions, :return, :indexed, :opcmp, :loops, :class, :test, :regex, :slurpy, :gather, :other, :alias, :assignment, :bool, :blocks, :constants, :continuation, :freeze, :gc, :nil, :proc, :range, :splat, :time, :yield, :zip]

    desc "Run the entire test suite."
    task :all => [:basic, "array:all", "file:all", "hash:all", "integer:all", "kernel:all", "math:all", "range:all", "string:all"] do
        dur_seconds = Time.now.to_i - $start.to_i
        dur_minutes = 0
        while dur_seconds > 60
            dur_seconds -= 60
            dur_minutes += 1
        end
        puts "Test statistics:"
        puts " The test suite took #{dur_minutes}:#{dur_seconds}."
        puts " #{$tests} tests were run, from #{$test_files} files."
        puts " #{$ok} tests passed, #{$unexpected_passes} of which were unexpected." 
        unless $u_p_files.empty?
            $u_p_files.uniq!
            $pl = $u_p_files.length > 1
            puts " Unexpected passes were found in the following #{pl "file"}:"
            $u_p_files.each do |pass|
                puts "  #{pass}"
            end
        end
        $pl = $nok > 1
        puts " #{$nok} #{pl "test"} failed, #{$expected_failures} of which were expected."
        unless $unexpected_failures.empty?
            $unexpected_failures.uniq!
            $pl = $unexpected_failures.size > 1
            puts " Unexpected #{pl "failure"} #{were} found in the following #{pl "file"}:"
            $unexpected_failures.each do |fail|
                puts "  #{fail}"
            end
        end
        $pl = $missing_files.size > 1
        unless $missing_files.empty?
            puts " There #{were} #{$missing} test #{pl "file"} that reported fewer results than were planned:"
            $missing_files.uniq!
            $missing_files.each do |missing|
                puts "  #{missing}"
            end
        end
        $pl = $toomany_files.size > 1
        unless $toomany_files.empty?
            puts " There #{were} #{$toomany} test #{pl "file"} that reported more results than were planned:"
            $toomany_files.uniq!
            $toomany_files.each do |toomany|
                puts "  #{toomany}"
            end
        end
        $pl = $unknown > 1
        puts " There #{were} #{$unknown} unknown or confusing #{pl "result"}." if $unknown > 0
        $pl = $failures > 1
        puts " There #{were} #{$failures} complete #{pl "failure"}." if $failures > 0
        $pl = $issue_lacks.size > 1
        unless $i_l_files.empty?
            puts " There #{were} #{$issue_lacks} #{pl "test"} that used todo or skip without noting an issue number, found in:"
            $i_l_files.uniq!
            $i_l_files.each do |file|
                puts "  #{file}"
            end
        end
        $pl = $comp_fails > 1
        unless $c_f_files.empty?
            puts " There #{were} #{$comp_fails} #{pl "file"} that completely failed to compile:"
            $c_f_files.uniq!
            $c_f_files.each do |file|
                puts "  #{file}"
            end
        end
        puts " -- CLEAN FOR COMMIT --" if clean?
    end

    desc "Run test:all *and* produce stats about known issues."
    task :stats => [:all] do
        $pl = $issue_counts.size > 1
        unless $issue_counts.empty?
            puts " The following #{are} the #{pl "issue"} currently known to affect the tests, and a count of the fails associated with #{them}:"
            $issue_counts.each do |issue, count|
                $pl = count > 1
                puts "  Issue ##{issue}: #{count} #{pl "fail"}"
            end
        else
            puts " There are no issues currently known to affect the tests."
        end
    end
end
