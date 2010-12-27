## $Id$

=head1 TITLE

FalseClass - Cardinal boolean class

=head1 DESCRIPTION

=cut

.namespace ['FalseClass']

.sub 'onload' :anon :init :load
    .local pmc cardinalmeta, falseproto
    cardinalmeta = get_hll_global ['CardinalObject'], '!CARDINALMETA'
    falseproto = cardinalmeta.'new_class'('FalseClass', 'parent'=>'CardinalObject parrot;Boolean')

    $P0 = new 'FalseClass'
    set_hll_global 'false', $P0
.end

.sub '_get_bool' :vtable('get_bool') :method
    $P0 = new 'Boolean'
    $P0 = 0
    .return ($P0)
.end

.sub '_not' :vtable('neg') :method
    .param pmc wtf
    $P0 = get_hll_global 'true'
    .return ($P0)
.end

.sub 'to_s' :method :vtable('get_string')
    $S0 = "false"
    .return ($S0)
.end

# Local Variables:
#   mode: pir
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4 ft=pir:
