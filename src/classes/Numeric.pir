# $Id$

=head1 NAME

src/classes/Numeric.pir - Cardinal CardinalNumeric class and related functions

=cut

.namespace ['CardinalNumeric']

.sub 'onload' :anon :load :init
    .local pmc cardinalmeta, numericproto
    cardinalmeta = get_hll_global ['CardinalObject'], '!CARDINALMETA'
    numericproto = cardinalmeta.'new_class'('CardinalNumeric', 'parent'=>'CardinalObject')
.end
