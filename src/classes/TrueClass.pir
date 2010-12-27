## $Id$

=head1 TITLE

TrueClass - Cardinal boolean class

=head1 DESCRIPTION

=cut

.namespace ['TrueClass']

.sub 'onload' :anon :init :load
    .local pmc cardinalmeta, trueproto
    cardinalmeta = get_hll_global ['CardinalObject'], '!CARDINALMETA'
    trueproto = cardinalmeta.'new_class'('TrueClass', 'parent'=>'CardinalObject parrot;Boolean')

    $P0 = new 'TrueClass'
    set_hll_global 'true', $P0
.end

.sub '_get_bool' :vtable('get_bool') :method
    $P0 = new 'Boolean'
    $P0 = 1
    .return ($P0)
.end

.sub '_not' :vtable('neg') :method
    .param pmc wtf
    $P0 = get_hll_global 'false'
    .return ($P0)
.end

.sub 'to_s' :method :vtable('get_string')
    $S0 = "true"
    .return ($S0)
.end

# Local Variables:
#   mode: pir
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4 ft=pir:
