# Copyright (C) 2008, Parrot Foundation.
# $Id$

=begin comments

cardinal::Grammar::Actions - ast transformations for cardinal

This file contains the methods that are used by the parse grammar
to build the PAST representation of an cardinal program.
Each method below corresponds to a rule in F<src/parser/grammar.pg>,
and is invoked at the point where C<{*}> appears in the rule,
with the current match object as the first argument.  If the
line containing C<{*}> also has a C<#= key> comment, then the
value of the comment is passed as the second argument to the method.

=end comments
=cut

class cardinal::Grammar::Actions;

method TOP($/) {
    my $past := $<comp_stmt>.ast();
    $past.blocktype('declaration');
    $past.pirflags(':load :main');
    $past.hll('cardinal');

    my $init := PAST::Block.new();
    $init.push(
        PAST::Op.new( :inline('$P0 = compreg "cardinal"',
                              'unless null $P0 goto have_cardinal',
                              'load_bytecode "cardinal.pbc"',
                              'have_cardinal:') )
    );
    $init.hll('parrot');
    $init.pirflags(":init :load");
    $past.loadinit($init);

    our $?INIT;
        if defined( $?INIT ) {
        $?INIT.unshift(
            PAST::Var.new(
                :name('$def'),
                :scope('lexical'),
                :isdecl(1)
            )
        );
        $?INIT.blocktype('declaration');
        $?INIT.pirflags(':init :load');
        $past.unshift( $?INIT );
        $?INIT := PAST::Block.new(); # For the next eval.
    }

    make $past;
}

method comp_stmt($/,$key) {
    our $?BLOCK;
    our @?BLOCK;
    our $?BLOCK_SIGNATURED;
    if $key eq 'open' {
        if $?BLOCK_SIGNATURED {
            $?BLOCK := $?BLOCK_SIGNATURED;
            $?BLOCK_SIGNATURED := 0;
        }
        else {
            $?BLOCK := PAST::Block.new( PAST::Stmts.new(), :node($/));
            my $block := PAST::Var.new(:scope('parameter'), :named('!BLOCK'), :name('!BLOCK'), :viviself('Undef'));
            $?BLOCK.symbol($block.name(), :scope('lexical'));
            $?BLOCK[0].push($block);
        }
        @?BLOCK.unshift($?BLOCK);
    }
    if $key eq 'close' {
        my $past := @?BLOCK.shift();
        $?BLOCK := @?BLOCK[0];
        $past.push( $<stmts>.ast() );
        make $past;
    }
}

method stmts($/) {
    my $past := PAST::Stmts.new( :node($/) );
    for $<stmt> {
        $past.push($_.ast());
    }
    make $past;
}

method basic_stmt($/, $key) {
    make $/{$key}.ast();
}

method stmt($/) {
    my $past := $<basic_stmt>.ast();
    for $<stmt_mod> {
        my $modifier := $_.ast();
        $modifier.push($past);
        $past := $modifier;
    }
    make $past;
}

method stmt_mod($/) {
    my $op;
    if $<sym> eq 'until' {
        ## there is no :pasttype('until'); this is called repeat_until
        $op := 'repeat_until';
    }
    else {
        ## if, while and unless are valid :pasttypes.
        $op := ~$<sym>;
    }
    make PAST::Op.new( $<expr>.ast(), :pasttype($op), :node($/) );

}

method expr($/) {
    my $past := $<arg>.ast();
    if +$<not> {
        $past := PAST::Op.new( $past, :pirop('not'), :node($/) );
    }
    if $<expr> {
        my $op;
        if ~$<op>[0] eq 'and' { $op := 'if'; }
        else { $op := 'unless'; }
        $past := PAST::Op.new( $past, $<expr>[0].ast(), :pasttype($op), :node($/) );
    }
    make $past;
}

method return_stmt($/) {
    my $past := $<call_args>.ast();
    $past.pasttype('inline');
    $past.inline('    .return(%0)');
    make $past;
}

## not entirely sure what alias does, but this is a guess...
method alias($/) {
    my $fname := $<fname>[0];
    my $alias := $<fname>[1];
    make PAST::Op.new( $alias, $fname, :pasttype('bind'), :node($/) );
}

method begin($/) {
    my $past := $<comp_stmt>.ast();
    my $sub := PAST::Compiler.compile( $past );
    $sub();
    ## XXX what to do here? empty block? stolen from rakudo.
    make PAST::Block.new( :node($/) );
}

method end($/) {
    my $past := PAST::Block.new( $<comp_stmt>.ast(), :node($/) );
    $past.blocktype('declaration');
    my $sub := PAST::Compiler.compile( $past );
    Q:PIR {
      $P0 = get_hll_global ['cardinal'], '@?END_BLOCKS'
      $P1 = find_lex '$sub'
      push $P0, $P1
    };
    make $past;
}

method indexed_assignment($/) {
    my $keys;
    my $rhs := $<rhs>.ast();
    my $primary := $<basic_primary>.ast();

    $keys := $<keys>.ast();

    my $past := PAST::Op.new( :name('[]='), :pasttype('callmethod'), :node($/) );

    $past.push( $primary );

    while $keys[0] {
        $past.push( $keys.shift() );
    }

    $past.push( $rhs );

    make $past;
}
method member_assignment($/) {
    my $rhs := $<rhs>.ast();
    my $primary := $<basic_primary>.ast();

    my $past := PAST::Op.new( :name(~$<key><ident> ~ '='), :pasttype('callmethod'), :node($/) );

    $past.push( $primary );
    $past.push( $rhs );

    make $past;
}
method assignment($/) {
    my $lhs := $<mlhs>.ast();
    our $?BLOCK;
    my $name := $lhs.name();
    unless $?BLOCK.symbol(~$name) {
        our @?BLOCK;
        my $exists := 0;
        my $scope;
        for @?BLOCK {
            if $_ {
                my $sym_table := $_.symbol(~$name);
                if $sym_table {
                    $exists := 1;
                    $scope := '' ~ $sym_table<scope>;
                }
            }
        }
        our $?CLASS;
        if $exists == 0 && defined($?CLASS) {
            my $block := $?CLASS[0];
            my $sym_table := $block.symbol(~$name);
            if $sym_table {
                $exists := 1;
                $scope := '' ~ $sym_table<scope>;
            }
        }
        if $exists == 0 {
            $lhs.isdecl(1);
            $scope := 'lexical';
        }
        $?BLOCK.symbol(~$name, :scope($scope));
        $lhs.scope($scope);
    }

    my $rhs := $<mrhs>.ast();
    make PAST::Op.new( $lhs, $rhs, :pasttype('bind'), :lvalue(1), :node($/) );
}

method lhs($/, $key) {
    make $/{$key}.ast();
}

method member_variable($/) {
    make $<primary>.ast();
    # XXX fix field.
}

method indexed($/) {
    my $args;
    if $<args> {
        $args := $<args>[0].ast();
    }

    my $past := PAST::Op.new( :name('[]'), :pasttype('callmethod'), :node($/) );
    while $args[0] {
        $past.push( $args.shift() );
    }

    make $past;
}

method variable($/) {
    my $past;
    my $varname := $/<varname>;
    $past := $varname.ast();
    if is_a_sub(~$varname) { # unary sub
        $past := PAST::Op.new(:pasttype('call'), :node($varname), $past);
    }
    make $past;
}

method varname($/, $key) {
    make $/{$key}.ast();
}

method global($/) {
    my @namespace;
    our @?BLOCK;
    my $toplevel := @?BLOCK[0];
    $toplevel.symbol(~$/, :scope('package'), :namespace(@namespace));
    make PAST::Var.new( :name(~$/), :scope('package'), :namespace(@namespace), :viviself('Undef'), :node($/) );
}

method instance_variable($/) {
    our $?CLASS;
    our $?BLOCK;
    my $name := ~$/;
    my $past := PAST::Var.new(  :name($name), :scope('attribute'), :viviself('Undef'), :node($/) );
    my $block := $?CLASS[0];
    unless $block.symbol(~$/) {
        $?CLASS.push(
            PAST::Op.new(
                :pasttype('call'),
                :name('!keyword_has'),
                PAST::Var.new(
                    :name('$def'),
                    :scope('lexical')
                ),
                PAST::Val.new( :value($name) )
            )
        );

        $block.symbol(~$name, :scope('attribute'));
        $?BLOCK.symbol(~$name, :scope('attribute'));
    }
    make $past;
}

method class_variable($/) {
    our $?CLASS;
    our $?BLOCK;
    my $name := ~$/;
    my $past := PAST::Var.new(  :name($name), :scope('package'), :viviself('Undef'), :node($/) );
    my $block := $?CLASS[0];
    unless $block.symbol(~$/) {
        $block.symbol(~$name, :scope('package'));
        $?BLOCK.symbol(~$name, :scope('package'));
    }
    make $past;
}

method local_variable($/) {
    our $?BLOCK;
    my $past := PAST::Var.new( :name(~$<ident>), :node($/), :viviself('Undef') );
    if +$<ns> {
        $past.scope('package');
        $past.namespace(~$<ns>[0]);
    }
    elsif $?BLOCK.symbol($<ident>) {
        my $scope := '' ~ $?BLOCK.symbol($<ident>)<scope>;
        $past.scope(~$scope);
    }
    else {
        our @?BLOCK;
        my $exists := 0;
        my $scope;
        for @?BLOCK {
            if $_ {
                my $sym_table := $_.symbol(~$<ident>);
                if $sym_table {
                    $exists := 1;
                    $scope := '' ~ $sym_table<scope>;
                }
            }
        }
        if $exists == 0 {
            $past.scope('package');
            my @a;
            $past.namespace(@a);
        }
        else {
            $past.scope($scope);
        }
    }
    make $past;
}

method funcall($/) {
    my $past := $<local_variable>.ast();
    make $past;
}

method constant_variable($/) {
    my @a;
    my $name := ~$/;
    if $name eq 'Integer' { $name := "CardinalInteger"; }
    elsif $name eq 'String' { $name := "CardinalString"; }
    elsif $name eq 'Array' { $name := "CardinalArray"; }
    elsif $name eq 'Hash' { $name := "CardinalHash"; }
    elsif $name eq 'Range' { $name := "CardinalRange"; }
    elsif $name eq 'File' { $name := "CardinalFile"; }
    my $past := PAST::Var.new( :name($name), :scope('package'), :node($/), :viviself('Undef'), :namespace( @a ) );
    make $past;
}


method if_stmt($/) {
    my $cond := +$<expr> - 1;
    my $comp := $<comp_stmt>[$cond].ast();
    $comp.blocktype('immediate');
    my $past := PAST::Op.new( $<expr>[$cond].ast() ,
                              $comp,
                              :pasttype('if'),
                              :node( $/ )
                            );
    if ( $<else> ) {
        my $else := $<else>[0].ast() ;
        $else.blocktype('immediate');
        $past.push( $else );
    }
    while ($cond != 0) {
        $cond := $cond - 1;
        $comp := $<comp_stmt>[$cond].ast();
        $comp.blocktype('immediate');
        $past := PAST::Op.new( $<expr>[$cond].ast(),
                               $comp,
                               $past,
                               :pasttype('if'),
                               :node( $/ )
                             );
    }
    make $past;
}

method unless_stmt($/) {
    my $cond := $<expr>.ast();
    my $body := $<comp_stmt>.ast();
    $body.blocktype('immediate');
    my $past := PAST::Op.new( $cond, $body, :pasttype('unless'), :node($/) );
    if ( $<else> ) {
        # $past.push( $<else>[0].ast() );
	my $else := $<else>[0].ast();
	$else.blocktype('immediate');
	$past.push( $else );
    }
    make $past;
}

method else($/) {
    make $<comp_stmt>.ast();
}

method while_stmt($/) {
    my $cond := $<expr>.ast();
    my $body := $<comp_stmt>.ast();
    $body.blocktype('immediate');
    make PAST::Op.new( $cond, $body, :pasttype(~$<sym>), :node($/) );
}

method for_stmt($/) {
    my $list := $<expr>.ast();
    my $body := $<comp_stmt>.ast();
    my $var := $<variable>.ast();
    $body.blocktype('immediate');
    $var.scope('parameter');
    $var.isdecl(0);
    $body[0].push($var);
    make PAST::Op.new( $list, $body, :pasttype('for'), :node($/) );
}

method control_command($/,$key) {
    make PAST::Op.new(
            :pasttype('call'),
            :name(~$/),
        );
}

method yield($/) {
    our $?BLOCK;
    our @?BLOCK;
    my $blockname;
    if $?BLOCK.symbol('!BLOCK') {
        if defined($?BLOCK.symbol('!BLOCK')<name>) {
            $blockname := $?BLOCK.symbol('!BLOCK')<name>;
        }
        else {
            $blockname := '!BLOCK';
        }
    }
    my $call := $<call_args>.ast();
    $call.unshift( PAST::Var.new(:scope('lexical'), :name(~$blockname)));
    $call.node($/);
    make $call;
}

method module($/) {
    my $past := $<comp_stmt>.ast();
    my $name := $<module_identifier>.ast();
    $past.namespace( $name.name() );
    $past.blocktype('declaration');
    #$past.pirflags(':load :init');
    make $past;
}

method begin_end($/) {
    my $past := $<comp_stmt>.ast();
    # XXX handle resque and ensure clauses
    make $past;
}

method classdef($/,$key) {
    our $?CLASS;
    our @?CLASS;
    our $?INIT;

    my $name := ~$<module_identifier><ident>;
    if $key eq 'open' {
        my $decl := PAST::Stmts.new();
        $decl.push(
            PAST::Op.new(
                :pasttype('bind'),
                PAST::Var.new(
                    :name('$def'),
                    :scope('lexical')
                ),
                PAST::Op.new(
                    :pasttype('call'),
                    :name('!keyword_class'),
                    PAST::Val.new( :value($name) )
                )
            )
        );
        @?CLASS.unshift( $?CLASS );
        $?CLASS := $decl;
        $?CLASS.unshift( PAST::Block.new() );
    }
    else {
        my $block := $<comp_stmt>.ast();
        $block.namespace($name);
        $block.blocktype('declaration');
        $block.pirflags(':init :load');

        $?CLASS.push(
            PAST::Op.new(
                :pasttype('callmethod'),
                :name('register'),
                PAST::Var.new(
                    :scope('package'),
                    :name('!CARDINALMETA'),
                    :namespace('CardinalObject')
                ),
                PAST::Var.new(
                    :scope('lexical'),
                    :name('$def')
                ),
                PAST::Val.new(
                    :value('CardinalObject'),
                    :named( PAST::Val.new( :value('parent') ) )
                )
            )
        );

        unless defined( $?INIT ) {
            $?INIT := PAST::Block.new();
        }
        for @( $?CLASS ) {
            if $_.WHAT() eq 'Block' {
                $block.push( $_ );
            }
            else {
                $?INIT.push( $_ );
            }
        }

        # Restore outer class.
        if +@?CLASS {
            $?CLASS := @?CLASS.shift();
        }
        else {
            $?CLASS := @?CLASS[0];
        }


        make $block;
    }
}

method functiondef($/) {
    my $past := $<comp_stmt>.ast();
    my $name := $<fname>;
    my $arity := +$past[0]<arity>;
    #my $args := $<argdecl>.ast();
    #$past.push($args);
    $past.name(~$name);
    our $?BLOCK;
    our $?CLASS;
    $?BLOCK.symbol(~$name, :scope('package'), :arity($arity));
    if defined($?CLASS) {
        $past.pirflags(':method');
    }
    make $past;
}

method sig_identifier($/) {
    my $past := $<identifier>.ast();
    if +$<default> == 1 {
        $past.viviself( $<default>[0].ast() );
    }
    make $past;
}

method block_signature($/) {
    my $params := PAST::Stmts.new( :node($/) );
    my $past := PAST::Block.new($params, :blocktype('declaration'));
    for $<sig_identifier> {
        my $parameter := $_.ast();
        $past.symbol($parameter.name(), :scope('lexical'));
        $parameter.scope('parameter');
        $params.push($parameter);
    }
    if $<slurpy_param> {
        my $slurp := ($<slurpy_param>[0] || $<slurpy_param>).ast();
        $past.symbol($slurp.name(), :scope('lexical'));
        $params.push( $slurp );
    }

    if $<block_param> {
        my $block := $<block_param>[0].ast();
        $block.named('!BLOCK');
        $past.symbol($block.name(), :scope('lexical'));
        $past.symbol('!BLOCK', :name(~$block.name()));
        $params.push($block);
    }
    else {
        my $block := PAST::Var.new(:scope('parameter'), :named('!BLOCK'), :name('!BLOCK'), :viviself('Undef'));
        $past.symbol($block.name(), :scope('lexical'));
        $params.push($block);
    }
    $params.arity( +$<sig_identifier> + +$<block_param> );
    our $?BLOCK_SIGNATURED := $past;
    make $past;
}

method slurpy_param($/) {
    my $past := $<identifier>.ast();
    $past.slurpy(1);
    $past.scope('parameter');
    make $past;
}

method block_param($/) {
    my $past := $<identifier>.ast();
    $past.scope('parameter');
    make $past;
}

method identifier($/) {
    make PAST::Var.new( :name(~$<ident>), :node($/) );
}

method module_identifier($/) {
    make PAST::Var.new( :name(~$/), :scope('package'), :node($/) );
}

method methodcall($/) {
    my $op := $<operation>;
    my $past;
    if $<call_args> {
        $past := $<call_args>[0].ast();
    }
    else {
        $past := PAST::Op.new();
    }

    $past.pasttype('callmethod');

    if $<do_block> {
        $past.push( $<do_block>[0].ast() );
    }

    $past.name(~$op);
    make $past;
}

method do_block($/) {
    my $past := $<comp_stmt>.ast();
    make $past;
}

method super_call($/) {
    my $past := $<call_args>.ast();
    ## how to invoke super.xxx ?
    make $past;
}

method operation($/) {
    make $<identifier>.ast();
}

method call_args($/) {
    my $past;
    if $<args> {
        $past := $<args>.ast();
    }
    else {
        $past := PAST::Op.new( :pasttype('call'), :node($/) );
    }
    if $<do_block> {
        my $do := $<do_block>[0].ast();
        $do.named(PAST::Val.new(:value('!BLOCK')));
        $past.push($do);
    }
    make $past;
}

method args($/) {
    my $past := PAST::Op.new( :pasttype('call'), :node($/) );
    for $<arg> {
        $past.push( $_.ast() );
    }
    make $past;
}

method basic_primary($/, $key) {
    make $/{$key}.ast();
}

method primary($/) {
    my $past := $<basic_primary>.ast();

    # XXX check this out:
    for $<post_primary_expr> {
        my $postexpr := $_.ast();
        $postexpr.unshift($past);
        $past := $postexpr;
    }
    make $past;
}

method post_primary_expr($/, $key) {
    make $/{$key}.ast();
}

method scope_identifier($/) {
    make $<identifier>.ast();
    # XXX handle :: operator.
}

method literal($/, $key) {
    my $past;
    if $key eq 'true' {
        $past := PAST::Op.new(:inline("%t = get_hll_global 'true'"), :returns('Bool'));
    } elsif $key eq 'false' {
        $past := PAST::Op.new(:inline("%t = get_hll_global 'false'"), :returns('Bool'));
    } elsif $key eq 'nil' {
        $past := PAST::Op.new(:inline("%t = get_hll_global 'nil'"), :returns('NilClass'));
    } elsif $key eq 'self' {
        $past := PAST::Op.new(:inline('%r = self'));
    } else {
        $past := $/{$key}.ast();
    }
    make $past;
}

method pcomp_stmt($/) {
    make $<comp_stmt>.ast();
}

method quote_string($/) {
    make $<quote_expression>.ast();
}

method warray($/) {
    make $<quote_expression>.ast();
}

method array($/) {
    my $list;
    if $<args> {
        $list := $<args>[0].ast();
        $list.name('list');
    }
    else {
        $list := PAST::Op.new( :name('list'), :node($/) );
    }

    make $list;
}

method ahash($/) {
    my $hash := PAST::Op.new( :name('hash'), :node($/) );
    if $<assocs> {
        my $items := $<assocs>[0].ast();
        for @($items) {
            $hash.push( $_ );
        }
    }
    make $hash;
}

method assocs($/) {
    my $assoc := PAST::Stmts.new(:node($/));
    for $<assoc> {
        my $item := $_.ast();
        $assoc.push($item);
    }
    make $assoc;
}

method assoc($/) {
    my $past := PAST::Op.new(:name('list'), :node($/));
    $past.push( $<arg>[0].ast() );
    $past.push( $<arg>[1].ast() );
    make $past;
}

method float($/) {
    make PAST::Val.new( :value( ~$/ ), :returns('Float'), :node($/) );
}

method integer($/) {
    make PAST::Val.new( :value( ~$/ ), :returns('CardinalInteger'), :node($/) );
}

method string($/) {
    make $<quote_expression>.ast();
}

method regex($/) {
    make $<quote_expression>.ast();
}

method quote_expression($/, $key) {
    my $past;
    if $key eq 'quote_regex' {
        our $?NS;
        $past := PAST::Block.new(
            $<quote_regex>,
            :compiler('PGE::Perl6Regex'),
            :namespace($?NS),
            :blocktype('declaration'),
            :node( $/ )
        );
    }
    elsif $key eq 'quote_concat' {
        if +$<quote_concat> == 1 {
            $past := $<quote_concat>[0].ast();
        }
        else {
            $past := PAST::Op.new(
                :name('list'),
                :pasttype('call'),
                :node( $/ )
            );
            for $<quote_concat> {
                $past.push( $_.ast() );
            }
        }
    }
    make $past;
}


method quote_concat($/) {
    my $terms := +$<quote_term>;
    my $count := 1;
    my $past := $<quote_term>[0].ast();
    while ($count != $terms) {
        $past := PAST::Op.new(
            $past,
            $<quote_term>[$count].ast(),
            :pirop('concat'),
            :pasttype('pirop')
        );
        $count := $count + 1;
    }
    make $past;
}


method quote_term($/, $key) {
    my $past;
    if ($key eq 'literal') {
        $past := PAST::Val.new(
            :value( ~$<quote_literal>.ast ),
            :returns('CardinalString'), :node($/)
        );
    }
    elsif ($key eq 'variable') {
        $past := $<variable>.ast();
    }
    elsif ($key eq 'do_block') {
        my $block := $<do_block>.ast();
        if $block.WHAT() eq 'Block' {
            $block.blocktype('immediate');
        }
        $past := PAST::Op.new(:pasttype('call'));
        $past.push($block);
    }
    make $past;
}

method arg($/, $key) {
    ## Handle the operator table
    ##
    if ($key eq 'end') {
        make $<expr>.ast();
    }
    else {
        my $past := PAST::Op.new( :name($<type>),
                                  :pasttype($<top><pasttype>),
                                  :pirop($<top><pirop>),
                                  :lvalue($<top><lvalue>),
                                  :node($/)
                                );
        for @($/) {
            $past.push( $_.ast() );
        }
        make $past;
    }
}

sub is_a_sub($name) {
    our $?BLOCK;
    our @?BLOCK;
    if $?BLOCK.symbol(~$name) {
        if defined($?BLOCK.symbol(~$name)<arity>) {
            return 1;
        }
        else {
            return 0;
        }
    }
    for @?BLOCK {
        if $_ {
            my $sym_table := $_.symbol(~$name);
            if $sym_table {
                if defined($sym_table<arity>) {
                    return 1;
                }
                else {
                    return 0;
                }
            }
        }
    }
    my $lex := lex_lookup($name);
    if defined($lex) && ~lookup_class($lex) eq 'Sub' { return 1; }
    return 0;
}

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:

