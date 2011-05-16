#!/usr/bin/env parrot
# Copyright (C) 2009-2010, Parrot Foundation.

=head1 NAME

setup.pir - Python distutils style

=head1 DESCRIPTION

No Configure step, no Makefile generated.

See <runtime/parrot/library/distutils.pir>.

=head1 USAGE

    $ parrot setup.pir build
    $ parrot setup.pir test
    $ sudo parrot setup.pir install

=cut

.sub 'main' :main
    .param pmc args
    $S0 = shift args
    load_bytecode 'distutils.pbc'
    .local pmc config
    config = get_config()

    .const 'Sub' postbuild = 'postbuild'
    register_step_after('build', postbuild)

    .const 'Sub' clean = 'clean'
    register_step_before('clean', clean)

    .const 'Sub' arraytest = 'arraytest'
    register_step('arraytest', arraytest)

    .const 'Sub' hashtest = 'hashtest'
    register_step('hashtest', hashtest)

    $P0 = new 'Hash'
    $P0['name'] = 'Cardinal'
    $P0['abstract'] = 'Cardinal - Ruby compiler for Parrot'
    $P0['authority'] = 'http://github.com/cardinal'
    $P0['description'] = 'Cardinal is a Ruby compiler for Parrot.'
    $P1 = split ',', 'ruby'
    $P0['keywords'] = $P1
    $P0['license_type'] = 'Artistic License 2.0'
    $P0['license_uri'] = 'http://www.perlfoundation.org/artistic_license_2_0'
    $P0['copyright_holder'] = 'Parrot Foundation'
    $P0['checkout_uri'] = 'git://github.com/cardinal/cardinal.git'
    $P0['browser_uri'] = 'http://github.com/cardinal/cardinal'
    $P0['project_uri'] = 'http://github.com/cardinal/cardinal'

    # build
    $P2 = new 'Hash'
    $P2['src/gen_grammar.pir'] = 'src/parser/grammar.pg'
    $P0['pir_pge'] = $P2

    $P3 = new 'Hash'
    $P3['src/gen_actions.pir'] = 'src/parser/actions.pm'
    $P0['pir_nqp'] = $P3

    $P9 = split "\n", <<'BUILTINS_PIR'
src/builtins/guts.pir
src/builtins/control.pir
src/builtins/say.pir
src/builtins/cmp.pir
src/builtins/op.pir
src/classes/Object.pir
src/classes/Exception.pir
src/classes/NilClass.pir
src/classes/String.pir
src/classes/Numeric.pir
src/classes/Integer.pir
src/classes/Float.pir
src/classes/Array.pir
src/classes/Hash.pir
src/classes/Range.pir
src/classes/TrueClass.pir
src/classes/FalseClass.pir
src/classes/Kernel.pir
src/classes/Time.pir
src/classes/Math.pir
src/classes/GC.pir
src/classes/IO.pir
src/classes/Proc.pir
src/classes/File.pir
src/classes/FileStat.pir
src/classes/Dir.pir
src/builtins/globals.pir
src/builtins/eval.pir
src/classes/Continuation.pir
BUILTINS_PIR
    $S0 = pop $P9
    $P10 = new 'Hash'
    $P10['src/gen_builtins.pir'] = $P9
    $P0['inc_pir'] = $P10

    $P4 = new 'Hash'
    $P5 = split "\n", <<'SOURCES'
cardinal.pir
src/parser/quote_expression.pir
src/gen_grammar.pir
src/gen_actions.pir
src/gen_builtins.pir
SOURCES
    $S0 = pop $P5
    $P4['cardinal.pbc'] = $P5
    $P0['pbc_pir'] = $P4

    $P6 = new 'Hash'
    $P6['parrot-cardinal'] = 'cardinal.pbc'
    $P0['installable_pbc'] = $P6

    # test
    $S0 = get_parrot()
    $S0 .= ' cardinal.pbc'
    $P0['prove_exec'] = $S0
    $P0['prove_files'] = 't/*.t t/*/*.t'

    # smoke
    $P7 = new 'Hash'
    $S0 = config['archname']
    $P7['Architecture'] = $S0
    $S0 = config['osname']
    $P7['Platform'] = $S0
    $S0 = config['revision']
    $P7['Parrot Revision'] = $S0
    $S0 = get_submitter()
    $P7['Submitter'] = $S0
    $P0['smolder_extra_properties'] = $P7
    $S0 = get_tags()
    $P0['smolder_tags'] = $S0
    $P0['prove_archive'] = 'report.tar.gz'
    $P0['smolder_url'] = 'http://smolder.parrot.org/app/projects/process_add_report/10'

    # dist
    $P8 = glob('Test.rb Rakefile')
    $P0['manifest_includes'] = $P8
    $P0['doc_files'] = 'README'

    .tailcall setup(args :flat, $P0 :flat :named)
.end

.sub 'postbuild' :anon
    .param pmc kv :slurpy :named
    $P1 = split ' ', 'Test.rb cardinal.pbc'
    $I0 = newer('Test.pir', $P1)
    if $I0 goto L1
    .local string cmd
    cmd = get_parrot()
    cmd .= ' cardinal.pbc --target=pir --output=Test.pir Test.rb'
    system(cmd, 1 :named('verbose'))
  L1:
.end

.sub 'clean' :anon
    .param pmc kv :slurpy :named
    unlink('Test.pir', 1 :named('verbose'))
.end

.sub 'arraytest' :anon
    .param pmc kv :slurpy :named
    run_step('build', kv :flat :named)

    $P0 = glob('t/array/*.t')
    $P0 = sort_strings($P0)
    $S0 = get_parrot()
    $S0 .= ' cardinal.pbc'
    runtests($P0 :flat, $S0 :named('exec'))
.end

.sub 'hashtest' :anon
    .param pmc kv :slurpy :named
    run_step('build', kv :flat :named)

    $P0 = glob('t/hash/*.t')
    $P0 = sort_strings($P0)
    $S0 = get_parrot()
    $S0 .= ' cardinal.pbc'
    runtests($P0 :flat, $S0 :named('exec'))
.end

.sub 'get_tags' :anon
    .local string tags
    .local pmc config
    config = get_config()
    tags = config['osname']
    tags .= ", "
    $S0 = config['archname']
    tags .= $S0
    .return (tags)
.end

.sub 'get_submitter' :anon
    $P0 = new 'Env'
    $I0 = exists $P0['SMOLDER_SUBMITTER']
    unless $I0 goto L1
    $S0 = $P0['SMOLDER_SUBMITTER']
    .return ($S0)
  L1:
    .return ('')
.end


# Local Variables:
#   mode: pir
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4 ft=pir:
