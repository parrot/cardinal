# $Id$

=head1 NAME

src/classes/Float.pir - Cardinal CardinalFloat class and related functions

=head1 Methods

=over

=item onload()

initialize CardinalFloat and it's inheritance

=cut

.namespace ['CardinalFloat']

.sub 'onload' :anon :load :init
    .local pmc cardinalmeta, floatproto
    cardinalmeta = get_hll_global ['CardinalObject'], '!CARDINALMETA'
    floatproto = cardinalmeta.'new_class'('CardinalFloat', 'parent'=>'parrot;Float CardinalNumeric')
    cardinalmeta.'register'('Float', 'parent'=>'CardinalObject', 'protoobject'=>floatproto)
.end

=item to_f()

return C<self>

=cut

.sub 'to_f' :method
    .return (self)
.end

=item zero?()

return true when if C<self> is 0.0

=cut

.sub 'zero?' :method
    eq self, 0.0, is_zero

    $P0 = get_hll_global 'false'
    goto done

  is_zero:
    $P0 = get_hll_global 'true'
  done:
    .return ($P0)
.end

=back

=cut
