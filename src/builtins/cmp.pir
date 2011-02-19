## $Id$

=head1 NAME

src/builtins/cmp.pir - Cardinal comparison builtins
Swiped from Rakudo.

=head1 Functions

=over 4

=cut

.namespace []


.sub 'bool'
    .param pmc a
    if a goto a_true
    $P0 = get_hll_global 'false'
    .return ($P0)
  a_true:
    $P0 = get_hll_global 'true'
    .return ($P0)
.end

.sub 'not_bool'
    .param pmc a
    if a goto a_true
    $P0 = get_hll_global 'true'
    .return ($P0)
  a_true:
    $P0 = get_hll_global 'false'
    .return ($P0)
.end

.sub 'infix:==' :multi(_,_)
    .param pmc a
    .param pmc b
    $I0 = iseq a, b
    .tailcall 'bool'($I0)
.end

.sub 'infix:==' :multi(TrueClass,TrueClass)
    .param pmc a
    .param pmc b
    $P0 = get_hll_global 'true'
    .return ($P0)
.end

.sub 'infix:==' :multi(FalseClass,FalseClass)
    .param pmc a
    .param pmc b
    $P0 = get_hll_global 'true'
    .return ($P0)
.end

.sub 'infix:==' :multi(TrueClass,_)
    .param pmc a
    .param pmc b
    $P0 = get_hll_global 'false'
    .return ($P0)
.end

.sub 'infix:==' :multi(FalseClass,_)
    .param pmc a
    .param pmc b
    $P0 = get_hll_global 'false'
    .return ($P0)
.end

.sub 'infix:==' :multi(_,TrueClass)
    .param pmc a
    .param pmc b
    $P0 = get_hll_global 'false'
    .return ($P0)
.end

.sub 'infix:==' :multi(_,FalseClass)
    .param pmc a
    .param pmc b
    $P0 = get_hll_global 'false'
    .return ($P0)
.end


.sub 'infix:==' :multi(Integer,Integer)
    .param pmc a
    .param pmc b
    eq a, b, a_b_eq
    $P0 = get_hll_global 'false'
    .return($P0)
  a_b_eq:
    $P0 = get_hll_global 'true'
    .return($P0)
.end

.sub 'infix:==' :multi(String,String)
    .param pmc a
    .param pmc b
    $I0 = iseq a, b
    .tailcall 'bool'($I0)
.end

.sub 'infix:==' :multi(NilClass,_)
    .param pmc a
    .param pmc b
    # mmd tells us they are different types, so return false
    $P0 = get_hll_global 'false' 
    .return ($P0)
.end

.sub 'infix:==' :multi(_,NilClass)
    .param pmc a
    .param pmc b
    # mmd tells us they are different types, so return false
    $P0 = get_hll_global 'false'
    .return ($P0)
.end

.sub 'infix:==' :multi(NilClass,NilClass)
    .param pmc a
    .param pmc b
    # mmd tells us they are same types and both of type NilClass, so return true
    $P0 = get_hll_global 'true'
    .return ($P0)
.end

.sub 'infix:==' :multi(CardinalArray,CardinalArray)
    .param pmc a
    .param pmc b
    .local int i
    $I1 = elements a
    $I2 = elements b
    ne $I1, $I2, fail
    i = 0
  loop:
    unless i < $I1 goto success
    $P0 = a[i]
    $P1 = b[i]
    $P0 = 'infix:=='($P0,$P1)
    inc i
    if $P0 goto loop
  fail:
    $P0 = get_hll_global 'false'
    .return ($P0)
  success:
    $P0 = get_hll_global 'true'
    .return ($P0)
.end


.sub 'infix:!=' :multi(_,_)
    .param pmc a
    .param pmc b
    $P0 = 'infix:=='(a, b)
    $P0 = not_bool($P0)
    .return ($P0)
.end


.sub 'infix:<' :multi(_,_)
    .param pmc a
    .param pmc b
    $I0 = islt a, b
    .tailcall 'bool'($I0)
.end

.sub 'infix:<' :multi(Integer,Integer)
    .param pmc a
    .param pmc b
    # creating a specific multi method
    # where marshall into the correct register type
    # gave a much needed boost in performance. Will investigate this later.
    $I0 = a
    $I1 = b
    #$I0 = islt a, b
    $I0 = islt $I0, $I1
    .tailcall 'bool'($I0)
.end


.sub 'infix:<=' :multi(_,_)
    .param pmc a
    .param pmc b
    $I0 = isle a, b
    .tailcall 'bool'($I0)
.end


.sub 'infix:>' :multi(_,_)
    .param pmc a
    .param pmc b
    $I0 = isgt a, b
    .tailcall 'bool'($I0)
.end


.sub 'infix:>=' :multi(_,_)
    .param pmc a
    .param pmc b
    $I0 = isge a, b
    .tailcall 'bool'($I0)
.end


.sub 'infix:<=>' :multi(_,_)
    .param pmc a
    .param pmc b
    $I0 = cmp a, b
    .return ($I0)
.end

.sub 'infix:=~'
    .param pmc topic
    .param pmc x
    .tailcall x(topic)
.end

.sub 'infix:!~'
    .param pmc topic
    .param pmc x
    $P0 = x(topic)
    $P0 = not_bool($P0)
    .return ($P0)
.end

=back

=cut

# Local Variables:
#   mode: pir
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4 ft=pir:
