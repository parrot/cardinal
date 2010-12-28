# $Id$

=head1

builtin functions for Ruby.

=cut

.namespace []

.sub 'print'
    .param pmc args            :slurpy
    .local pmc it
    it = iter args
  iter_loop:
    unless it goto iter_end
    $P0 = shift it
    print $P0
    goto iter_loop
  iter_end:
    $P0 = get_hll_global 'nil'
    .return($P0)
.end

.sub 'puts'
    .param pmc args            :slurpy
    $S0 = join "\n", args
    .tailcall 'print'($S0, "\n")
.end

.sub 'p'
    .param pmc args            :slurpy
    $S0 = join "\n", args
    .tailcall 'print'($S0, "\n")
.end

.include 'stdio.pasm'

.sub 'readline'
    #.param pmc sep              :optional #record sep
    $P0 = getinterp
    $P0 = $P0.'stdin_handle'()
    $S0 = $P0.'readline'('')
    .return($S0)
.end

.sub 'printf'
    .param pmc fmt
    .param pmc args             :slurpy
    $P0 = get_hll_global ['Kernel'], '!CARDINALMETA'
    .tailcall $P0.'printf'(fmt, args :flat)
.end

.sub 'sprintf'
    .param pmc fmt
    .param pmc args             :slurpy
    $P0 = get_hll_global ['Kernel'], '!CARDINALMETA'
    $P1 = $P0.'sprintf'(fmt, args :flat)
    .return ($P1)
.end

# Local Variables:
#   mode: pir
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4 ft=pir:

