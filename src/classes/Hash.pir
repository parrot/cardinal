## $Id$

=head1 NAME

src/classes/CardinalHash.pir - Cardinal hash class and related functions

=head1 Methods

=over 4

=cut

.namespace ['CardinalHash']

.sub 'onload' :anon :load :init
    .local pmc cardinalmeta, mappingproto
    cardinalmeta = get_hll_global ['CardinalObject'], '!CARDINALMETA'
    mappingproto = cardinalmeta.'new_class'('CardinalHash', 'parent'=>'parrot;Hash CardinalObject')
    cardinalmeta.'register'('Hash', 'parent'=>'CardinalObject', 'protoobject'=>mappingproto)
    $P0 = get_class 'CardinalHash'
    addattribute $P0, 'default'
.end


.sub 'get_string' :vtable :method
    $S0 = '{'
    .local pmc it
    it = iter self
    goto loop_start
  loop:
    unless it goto end
    $S0 = concat $S0, ','
  loop_start:
    $S1 = shift it
    $S2 = it[$S1]
    $S0 = concat $S0, $S1
    $S0 = concat $S0, '=>'
    $S0 = concat $S0, $S2
    goto loop
  end:
    $S0 = concat $S0, '}'
    .return ($S0)
.end

=item to_s (method)

Returns a string of keys and values appended together.

=cut

.sub 'to_s' :method
    .local pmc it
    .local pmc rv
    it = iter self
    rv   = new 'CardinalString'
  loop:
    unless it goto end
    $S1 = shift it
    rv = concat rv, $S1
    $S1 = it[$S1]
    rv = concat rv, $S1
    goto loop
  end:
    .return (rv)
.end



=item kv (method)

Returns elements of hash as array of C<Pair(key, value)>

=cut

.sub 'kv' :method
    .local pmc it
    .local pmc rv
    it = iter self
    rv   = new 'CardinalArray'
  loop:
    unless it goto end
    $S1 = shift it
    push rv, $S1
    $S1 = it[$S1]
    push rv, $S1
    goto loop
  end:
    .return (rv)
.end



.sub 'keys' :method
    .local pmc it
    .local pmc rv
    it = iter self
    rv   = new 'CardinalArray'
  loop:
    unless it goto end
    $S1 = shift it
    push rv, $S1
    goto loop
  end:
    .return (rv)
.end


.sub 'values' :method
    .local pmc it
    .local pmc rv
    it = iter self
    rv   = new 'CardinalArray'
  loop:
    unless it goto end
    $S1 = shift it
    $S1 = it[$S1]
    push rv, $S1
    goto loop
  end:
    .return (rv)
.end

=item each(block)

Run C<block> once for each item in C<self>, with the key and value passed as args.

=cut

.sub 'each' :method
    .param pmc block
    .local pmc it
    it = iter self
  each_loop:
    unless it goto each_loop_end
    $P1 = shift it
    $P2 = it[$P1]
    block($P1,$P2)
    goto each_loop
  each_loop_end:
.end

.sub 'to_a' :method
    .local pmc newlist
    .local pmc item
    .local pmc it
    newlist = new 'CardinalArray'
    it = iter self
  each_loop:
    unless it goto each_loop_end
    $P1 = shift it
    $P2 = it[$P1]
    item = new 'CardinalArray'
    push item, $P1
    push item, $P2
    push newlist, item
    goto each_loop
  each_loop_end:
    .return (newlist)
.end


## FIXME:  Parrot currently requires us to write our own "clone" method.
.sub 'clone' :vtable :method
    $P0 = new 'CardinalHash'
    .local pmc it
    it = iter self
  loop:
    unless it goto end
    $P1 = shift it
    $P2 = it[$P1]
    $P0[$P1] = $P2
    goto loop
  end:
    .return ($P0)
.end

.sub '[]' :method
    .param pmc i
    $P0 = self[i]
  unless_null $P0, index_return
    $P0 = getattribute self, 'default'
    .local string type
    type = typeof $P0
    $I0 = iseq type, 'Closure'
    unless $I0 goto index_return
    $P1 = $P0(self,i)
    $P0 = $P1
  index_return:
    .return($P0)
.end

.sub '[]=' :method
    .param pmc k
    .param pmc v
    self[k] = v
    .return(v)
.end

.sub 'has_key?' :method
    .param pmc key
    $I0 = exists self[key]
    if $I0 goto true
    $P0 = get_hll_global 'false'
    goto done
  true:
    $P0 = get_hll_global 'true'
  done:
    .return ($P0)
.end

.sub 'include?' :method
    .param pmc key
    $P0 = self.'has_key?'(key)
    .return ($P0)
.end

.sub 'key?' :method
    .param pmc key
    $P0 = self.'has_key?'(key)
    .return ($P0)
.end

.sub 'member?' :method
    .param pmc key
    $P0 = self.'has_key?'(key)
    .return ($P0)
.end

.sub 'has_value?' :method
    .param pmc key
    $I0 = defined self[key]
    if $I0 goto true
    $P0 = get_hll_global 'false'
    goto done
  true:
    $P0 = get_hll_global 'true'
  done:
    .return ($P0)
.end

.sub 'value?' :method
    .param pmc key
    $P0 = self.'has_value?'(key)
    .return ($P0)
.end

=back

=head1 Functions

=over 4

=back

=head1 TODO: Functions

=over 4

=cut

.namespace []

=item delete

 our List  multi method Hash::delete ( *@keys )
 our Scalar multi method Hash::delete ( $key ) is default

Deletes the elements specified by C<$key> or C<$keys> from the invocant.
returns the value(s) that were associated to those keys.

=item exists

 our Bool multi method Hash::exists ( $key )

True if invocant has an element whose key matches C<$key>, false
otherwise.

=item keys

=item kv

=cut

.sub kv :multi('Hash')
    .param pmc hash

    .tailcall hash.'kv'()
.end


=item pairs

=item values

 multi Int|List Hash::keys ( %hash : MatchTest *@keytests )
 multi Int|List Hash::kv ( %hash : MatchTest *@keytests )
 multi Int|(List of Pair) Hash::pairs  (%hash : MatchTest *@keytests )
 multi Int|List Hash::values ( %hash : MatchTest *@keytests )

Iterates the elements of C<%hash> in no apparent order, but the order
will be the same between successive calls to these functions, as long as
C<%hash> doesn't change.

If C<@keytests> are provided, only elements whose keys evaluate
C<$key ~~ any(@keytests)> as true are iterated.

What is returned at each element of the iteration varies with function.
C<keys> only returns the key; C<values> the value; C<kv> returns both as
a 2 element list in (key, value) order, C<pairs> a C<Pair(key, value)>.

Note that C<kv %hash> returns the same as C<zip(keys %hash; values %hash)>

In Scalar context, they all return the count of elements that would have
been iterated.

The lvalue form of C<keys> is not longer supported. Use the C<.buckets>
property instead.

=back

=cut

.namespace []

.sub 'infix:=>'
    .param pmc key
    .param pmc value
    $P1 = new 'CardinalArray'
    $P1.'push'(key)
    $P1.'push'(value)
    .return($P1)
.end

.sub 'hash'
    .param pmc pairs        :slurpy
    .local pmc ahash
    ahash = new 'CardinalHash'
    .local pmc item
  pairs_loop:
    unless pairs goto pairs_loop_end
    item = shift pairs
    $P0 = shift item
    $P1 = shift item
    ahash[$P0] = $P1
    goto pairs_loop
  pairs_loop_end:
    .return(ahash)
.end

.namespace ['Hash']

.sub 'new' :method :multi(_,P)
    .param pmc default
    $P0 = new 'CardinalHash'
    setattribute $P0, 'default', default
    .return ($P0)
.end

.sub 'new' :method :multi(_,'Sub')
    .param pmc a :optional :named('!BLOCK')
    $P0 = new 'CardinalHash'
    setattribute $P0, 'default', a
    .return($P0)
.end

# Local Variables:
#   mode: pir
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4 ft=pir:
