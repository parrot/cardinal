## $Id$

=head1 TITLE

CardinalInteger - Cardinal integers

=cut

.namespace [ 'CardinalInteger' ]


=head1 SUBROUTINES

=over 4

=item onload

=cut

.sub 'onload' :anon :init :load
    .local pmc cardinalmeta, intproto
    cardinalmeta = get_hll_global ['CardinalObject'], '!CARDINALMETA'
    intproto = cardinalmeta.'new_class'('CardinalInteger', 'parent'=>'parrot;Integer CardinalObject')
    cardinalmeta.'register'('Float', 'parent'=>'CardinalObject', 'protoobject'=>intproto)
.end

=item ACCEPTS()

=cut

.sub 'ACCEPTS' :method
    .param num topic
    .tailcall 'infix:=='(topic, self)
.end

=item perl()

Returns a Perl representation of the CardinalInteger.

=cut

.sub 'perl' :method
    $S0 = self
    .return($S0)
.end

.sub 'integer?' :method
  $P0 = get_hll_global 'true'
  .return($P0)
.end

=item _get_bool()

Return true when integers are queried about the their truth value

=cut

.sub '_get_bool' :vtable('get_bool') :method
    $P0 = new 'Boolean'
    $P0 = 1
    .return ($P0)
.end

=item to_s()

Returns a CardinalString representation of the CardinalInteger.

=cut

.sub 'to_s' :method
    $P0 = new 'CardinalString'
    $S0 = self
    $P0 = $S0
    .return($P0)
.end

=item
to_i()
to_int()
floor()
ceil()
round()
truncate()

All return C<self>

=cut

.sub 'to_i' :method
    .return(self)
.end

.sub 'to_int' :method
    .return(self)
.end

.sub 'floor' :method
    .return(self)
.end

.sub 'ceil' :method
    .return(self)
.end

.sub 'round' :method
    .return(self)
.end

.sub 'truncate' :method
    .return(self)
.end

.sub 'numerator' :method
    .return(self)
.end

=item

Returns 1

=cut

.sub 'denominator' :method
   $P0 = new 'CardinalInteger'
   $P0 = 1
   .return($P0)
.end


=item gcd(int)

Return the greatest common divisor of C<self> and num

=cut

.sub 'gcd' :method
   .param int other
   $I1 = self
   gcd $I0, $I1, other
   .return($I0)
.end

=item downto(n, block)

Runs C<block> for each integer from the current value of the Integer down to n.

=cut

.sub 'downto' :method
    .param int n
    .param pmc block :named('!BLOCK')
    $I1 = self
  downto_loop:
    $I0 = $I1 < n
    if $I0, downto_done
    block($I1)
    dec $I1
    goto downto_loop
  downto_done:
.end


=item upto(n, block)

Runs C<block> for each integer from the current value of the Integer up to n.

=cut

.sub 'upto' :method
    .param int n
    .param pmc block :named('!BLOCK')
    $I1 = self
  upto_loop:
    $I0 = $I1 > n
    if $I0, upto_done
    block($I1)
    inc $I1
    goto upto_loop
  upto_done:
.end

=item

Runs C<block> for integer from 0 to value of C<self>

=cut

.include "hllmacros.pir"
.sub 'times' :method
   .param pmc block :named('!BLOCK')
   $I0 = 0
   $I1 = self
   .While($I0 < $I1, {
        block($I0)
        inc $I0
   })
.end

=item succ()

Return C<self> plus 1

=cut

.sub 'succ' :method
  $P0 = new 'CardinalInteger'
  $P0 = 1
  $P1 = 'infix:+'($P0, self)
  .return ($P1)
.end

=item next()

Return C<self> plus 1

=cut

.sub 'next' :method
  $P0 = new 'CardinalInteger'
  $P0 = 1
  $P1 = 'infix:+'($P0, self)
  .return ($P1)
.end

=item pred()

Return C<self> minus 1

=cut

.sub 'pred' :method
    $P0 = new 'CardinalInteger'
    $P0 = 1
    $P1 = 'infix:-'(self, $P0)
    .return ($P1)
.end

=item chr()

Return a string represented by C<self>

=cut

.sub 'chr' :method
    .param pmc enc :optional
    .param int has_enc :opt_flag
    .local int val
    .local string tmp
    .local pmc rst

    val = self

    if has_enc goto decode
    if val > 0xff goto decode
    if val >= 0x80 goto str_conv
    if val < 0x00 goto range_error

  ascii:
    tmp = ''
    chr tmp, val
    rst = new 'CardinalString'
    rst = tmp
    goto done

  str_conv:
    rst = new 'CardinalString'
    rst = rst.'new'(val)
    goto done

  decode:
    # TODO:
    #
    # if has_enc : get encoding with enc. goto ascii when if enc is not valid 
    # if internal encoding is not null: decode with internal encoding
    # if internal encoding is null: goto RangeError
    print "Not Yet Implemented\n"

  range_error:
    # TODO:
    # payload in Exception
    $P0 = new 'RangeError'
    throw $P0

  done:
    .return (rst)
.end

=back

=cut

.namespace []

.sub 'infix:<' :multi('CardinalInteger', 'CardinalInteger')
    .param pmc this
    .param pmc that
    $I0 = this
    $I1 = that
    $I2 = islt $I0, $I1
    .tailcall 'bool'($I2)
.end

# Local Variables:
#   mode: pir
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4 ft=pir:
