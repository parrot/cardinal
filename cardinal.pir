=head1 TITLE

cardinal.pir - A cardinal compiler.

=head2 Description

This is the base file for the cardinal compiler.

This file includes the parsing and grammar rules from
the src/ directory, loads the relevant PGE libraries,
and registers the compiler under the name 'cardinal'.

=head2 Functions

=over 4

=item onload()

Creates the cardinal compiler using a C<PCT::HLLCompiler>
object.

=cut


.HLL 'cardinal'
.loadlib 'io_ops'
.loadlib 'sys_ops'
.loadlib 'trans_ops'
.loadlib 'obscure_ops'
.namespace []

.include 'src/gen_builtins.pir'

.sub 'onload' :anon :load :init
    load_bytecode 'PCT.pbc'
    .local pmc parrotns, cardinalns, exports
    parrotns = get_root_namespace ['parrot']
    cardinalns = get_hll_namespace
    exports = split ' ', 'PAST PCT PGE'
    parrotns.'export_to'(cardinalns, exports)
.end

.include 'src/gen_grammar.pir'
.include 'src/parser/quote_expression.pir'
.include 'src/gen_actions.pir'
.namespace [ 'cardinal';'Compiler' ]

#no caridinal_group found on my machine
#.loadlib 'cardinal_group'

.sub 'onload' :anon :load :init
    .local pmc cardinalmeta, compilerclass, compiler
    cardinalmeta = get_hll_global ['CardinalObject'], '!CARDINALMETA'
    compilerclass = cardinalmeta.'new_class'('cardinal::Compiler', 'parent'=>'PCT::HLLCompiler')

    $P2 = new 'CardinalString'
    $P2 = ""
    set_hll_global '$,', $P2

    compiler = compilerclass.'new'()
    compiler.'language'('cardinal')
    $P0 = get_hll_namespace ['cardinal';'Grammar']
    compiler.'parsegrammar'($P0)
    $P0 = get_hll_namespace ['cardinal';'Grammar';'Actions']
    compiler.'parseactions'($P0)

    compiler.'commandline_banner'("Cardinal - Ruby for the Parrot VM\n\n")
    compiler.'commandline_prompt'('crb(main):001:0> ')

     ##  create a list of END blocks to be run
    $P0 = new 'CardinalArray'
    set_hll_global ['cardinal'], '@?END_BLOCKS', $P0

    $P0 = new 'CardinalArray'
    set_hll_global ['cardinal';'Grammar';'Actions'], '@?BLOCK', $P0

    $P1 = get_hll_global ['PAST';'Compiler'], '%valflags'
    $P1['CardinalString'] = 'e'
.end

=item main(args :slurpy)  :main

Start compilation by passing any command line C<args>
to the cardinal compiler.

=cut

.sub 'main' :main
    .param pmc args_str

    ##  create ARGS global.
    .local pmc args, it
    args = new 'CardinalArray'
    it = iter args_str
    $P0 = shift it
  args_loop:
    unless it goto args_end
    $P0 = shift it
    push args, $P0
    goto args_loop
  args_end:
    set_hll_global 'ARGS', args

    $P0 = compreg 'cardinal'
    $P1 = $P0.'command_line'(args_str)

    .include 'iterator.pasm'
    $P0 = get_hll_global ['cardinal'], '@?END_BLOCKS'
    it = iter $P0
    it = .ITERATE_FROM_END
  iter_loop:
    unless it goto iter_end
    $P0 = pop it
    $P0()
    goto iter_loop
  iter_end:
.end

.sub 'load_library' :method
    .param pmc name
    .param pmc request :named :slurpy
    .local pmc name, retval, library, inc_hash
    $S0 = join '/', name
    retval = 'require'($S0, 'module'=>1)
    if null retval goto fail
    library = new 'Hash'
    library['name'] = name
    inc_hash = get_hll_global '%INC'
    $S0 = inc_hash[$S0]
    library['filename'] = $S0
    $P1 = new 'Hash'
    $P0 = get_hll_namespace name
    library['namespace'] = $P0
    $P1['ALL'] = $P0
    $P1['DEFAULT'] = $P0
    library['symbols'] = $P1
    .return (library)
  fail:
    .return (retval)
.end


=back

=cut

# Local Variables:
#   mode: pir
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4 ft=pir:

