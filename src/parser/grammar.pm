# $Id$

=begin overview

This is the grammar for cardinal written as a sequence of Perl 6 rules.

Originally taken (partly) from:
http://www.math.hokudai.ac.jp/~gotoken/ruby/man/yacc.html

and parse.y from the ruby source

=end overview

grammar cardinal::Grammar is HLL::Grammar;

token TOP {
    <comp_stmt>
    [ $ || <.panic('Syntax error')> ]
    {*}
}

token comp_stmt {
    {*}                        #= open
    <stmts>
    {*}                        #= close
}

rule stmts {
    <.term>?[ <stmt> [<.term>+ | <.before <end_block>> | $ | <panic('unterminated statement')>] ]* {*}
}

token term { \h*\n | \h*';' }
token end_block { <.ws> [ 'end' | '}' ] }

token basic_stmt {
    | <alias> {*}           #= alias
    | <classdef> {*}        #= classdef
    | <functiondef> {*}     #= functiondef
    | <if_stmt> {*}         #= if_stmt
    | <while_stmt> {*}      #= while_stmt
    | <for_stmt> {*}        #= for_stmt
    | <unless_stmt> {*}     #= unless_stmt
    | <module> {*}          #= module
    | <begin_end> {*}       #= begin_end
    | <indexed_assignment> {*}      #= indexed_assignment
    | <member_assignment> {*}      #= member_assignment
    | <assignment> {*}      #= assignment
    | <return_stmt> {*}     #= return_stmt
    | <expr> {*}            #= expr
    | <begin> {*}           #= begin
    | <end> {*}             #= end
}

token return_stmt {
    'return' <.ws> <call_args> {*}
}

rule alias {
    'alias' <fname> <fname>
    {*}
}

token stmt {
    <basic_stmt> <.ws> <stmt_mod>*
    {*}
}

token stmt_mod {
    $<sym>=[if|while|unless|until] <.ws> <expr>
    {*}
}

rule expr {
    [$<not>=['!'|'not']]? <EXPR> [$<op>=['and'|'or'] <expr>]?
    {*}
}

rule begin {
    'BEGIN' '{' <comp_stmt> '}'
    {*}
}

rule end {
    'END' '{' <comp_stmt> '}'
    {*}
}

token indexed_assignment {
    <basic_primary> '[' $<keys>=<args> ']' <.ws> '=' <.ws> $<rhs>=<EXPR>
    {*}
}

token member_assignment {
    <basic_primary> '.' $<key>=<identifier> <.ws> '=' <.ws> $<rhs>=<EXPR>
    {*}
}

rule assignment {
    $<mlhs>=<lhs> '=' $<mrhs>=<EXPR>       #XXX need to figure out multiple assignment
    {*}
}

token lhs {
    | <varname> {*} #= varname
}

token indexed {
    '[' <args>? ']'
    {*}
}

token member_variable {
    <primary> '.' <identifier>
    {*}
}

token methodcall {
    $<dot>='.'
    <operation> <call_args>? <do_block>?
    {*}
}

rule do_block {
    | 'do' <do_args>? <.term>? <.before <stmt>><comp_stmt> 'end' {*}
    | '{' <do_args>? <.term>? <.before <stmt>><comp_stmt> '}' {*}
}

rule super_call {
    'super' <call_args>
    {*}
}

token operation {
    'class'|
    'nil?' |
    'next' |
    'begin'|
    'end'  |
    '`'    |
    <.identifier> ('!'|'?')?
}

#XXX UGLY!  Refactor into <args> maybe?
token call_args {
    | [<.ws> <do_block>]**{1} {*}
    | '()' [<.ws> <do_block>]? {*}
    | [ <.after \s|\)> | <.before \s> ] <args> [<.ws> <do_block>]? {*}
    | '(' <.ws> <args> <.ws> ')' [<.ws> <do_block>]? {*}
}

rule do_args {
    '|' <block_signature> '|'
}

rule sig_identifier {
                      #XXX Should this be basic_primary or expr or what?
    <identifier>[ '=' <default=basic_primary>]? {*}
}

rule block_signature {
    [
    | <sig_identifier> [',' <sig_identifier>]* [',' <slurpy_param>]? [',' <block_param>]?
    | <slurpy_param> [',' <block_param>]?
    | <block_param>?
    ] {*}
}

token variable {
    <varname> {*}
}

token varname {
    <!reserved_word>
    [ <global> {*}             #= global
    | <class_variable> {*}     #= class_variable
    | <instance_variable> {*}  #= instance_variable
    | <local_variable> {*}     #= local_variable
    | <constant_variable> {*}  #= constant_variable
    ]
}

token funcall {
    <!reserved_word> <local_variable> <.before \s|'('> <.before <call_args>> {*}
}

rule args {
    <EXPR> [',' <EXPR>]*
    {*}
}

token basic_primary {
    | <literal> {*}                         #= literal
    | <funcall> {*}                         #= funcall
    | <variable> {*}                        #= variable
    | <pcomp_stmt> {*}                      #= pcomp_stmt
    | <yield> {*}                           #= yield
    | <control_command> {*}                 #= control_command
}

token primary {
    <basic_primary> <post_primary_expr>*
    {*}
}

token post_primary_expr {
    | <indexed> {*}            #= indexed
    | <call_args> {*}          #= call_args
    | <methodcall> {*}         #= methodcall
    | '[' <args>? ']' {*}      #= args
}

token pcomp_stmt {
    '(' <comp_stmt> ')'
    {*}
}


rule if_stmt {
    'if' <expr> <.then>
    [<comp_stmt>
    ['elsif' <expr> <.then>
    <comp_stmt>]*
    <else>?
    'end'
    |<panic('syntax error in if statement')>]
    {*}
}

token then { ':' | 'then' | <term> ['then']? }

rule while_stmt {
    $<sym>=['while'|'until'] <expr> <.do>
    <comp_stmt>
    'end'
    {*}
}

rule for_stmt {
    'for' <variable> 'in' <expr> <.do>
    <comp_stmt>
    'end'
    {*}
}

token do { ':' | 'do' | <term> ['do']? }

rule unless_stmt {
    'unless' <expr> <.then> <comp_stmt>
    <else>?
    'end'
    {*}
}

token else {
    'else' <.ws> <comp_stmt>
    {*}
}

token control_command {
    | 'next'  {*}                   #= next
    | 'break' {*}                   #= break
    | 'redo'  {*}                   #= redo
}

token yield {
    'yield' <call_args> {*}
}

rule module {
    'module' <module_identifier>
    <comp_stmt>
    'end'
    {*}
}

rule classdef {
    'class' <module_identifier> {*}  #= open
    <comp_stmt>
    'end'                       {*}  #= block
}

rule functiondef {
    'def' <fname> <argdecl>
    <comp_stmt>
    'end'
    {*}
}

rule argdecl {
    ['('
    <block_signature>
    ')']?
}

token slurpy_param {
    '*' <identifier>
    {*}
}

token block_param {
    '&' <identifier>
    {*}
}

rule begin_end {
    'begin'
    <comp_stmt>
    ['rescue' <args>? <.do> <comp_stmt>]+
    ['else' <comp_stmt>]?
    ['ensure' <comp_stmt>]?
    'end'
    {*}
}

token fname {
    <.identifier> <[=!?]>?
}

token quote_string {
    ['%q'|'%Q'] <.before <[<[_|({]>> <quote_EXPR: ':qq'>
    {*}
}

token warray {
    '%w' <.before <[<[({]>> <quote_EXPR: ':w :q'>
    {*}
}

rule array {
    '[' [ <args> [',']? ]? ']'
    {*}
}

rule ahash {
    '{' [ <assocs> [',']? ]? '}'
    {*}
}

rule assocs {
    <assoc> [',' <assoc>]*
    {*}
}

rule assoc {
    <EXPR> '=>' <EXPR>
    {*}
}

token identifier {
    <!reserved_word> <ident> {*}
}

token module_identifier {
    <.before <[A..Z]>> <ident>
    {*}
}

token global {
    '$' [
        | <ident> 
        | <[!@&`'+~=/\\,;.<>_*$?:"]>
        | <digit>+ 
        | '-'<[0adFiIlpvw]>
        ]
    {*}
}

token instance_variable {
    '@' <ident>
    {*}
}

token class_variable {
    '@@' <ident>
    {*}
}

token local_variable {
    [<ns=ident> '::']* [ <before <[a..z_]>> | <after '::'> ] <ident>
    {*}
}

token constant_variable {
    <.before <[A..Z]>> <.ident>
    {*}
}

token literal {
    | <float> {*}          #= float
    | <integer> {*}        #= integer
    | <string> {*}         #= string
    | <ahash> {*}          #= ahash
    | <regex> {*}          #= regex
    | <quote_string> {*}   #= quote_string
    | <warray> {*}         #= warray
    | <array> {*}          #= array
    | 'true' {*}           #= true
    | 'false' {*}          #= false
    | 'nil' {*}            #= nil
    | 'self' {*}           #= self
}

token float {
    '-'? \d+ '.' \d+
    {*}
}

token integer {
    '-'? \d+
    {*}
}

token string {
    [
    | <.before \'>     <quote_EXPR: ':q'>
    | <.before '"' >   <quote_EXPR: ':qq'>
    ]
    {*}
}

token regex {
    <.before '/'> [<quote_EXPR: ':regex'> $<modifiers>=[<alpha>]*
                  |<panic('problem parsing regex')>]
    {*}
}

token reserved_word {
    [alias|and|BEGIN|begin|break|case
    |class|def|defined|do|else|elsif
    |END|end|ensure|false|for|if
    |in|module|next|nil|not|or
    |redo|rescue|retry|return|self|super
    |then|true|undef|unless|until|when
    |while|yield|__FILE__|__LINE__]>>
}

token ws {
    | '\\' \n                      ## a backslash at end of line
    | <after [','|'='|'+']> \n     ## a newline after a comma or operator is ignored
    | \h* ['#' \N* \n* <ws>]?
}

INIT {
    cardinal::Grammar.O(':prec<x=>', '%muldiv');
    cardinal::Grammar.O(':prec<w=>', '%plusminus');
    cardinal::Grammar.O(':prec<v=>', '%bsh');
    cardinal::Grammar.O(':prec<t=>', '%band');
    cardinal::Grammar.O(':prec<r=>', '%bor');
    cardinal::Grammar.O(':prec<p=>', '%cmp');
    cardinal::Grammar.O(':prec<n=>', '%equality');
    cardinal::Grammar.O(':prec<l=>', '%and');
    cardinal::Grammar.O(':prec<j=>', '%or');
    cardinal::Grammar.O(':prec<h=>', '%dotdot');
    cardinal::Grammar.O(':prec<f=>', '%ternary');
    cardinal::Grammar.O(':prec<d=>, :assoc<right>', '%assignment'); # lvalue?
    cardinal::Grammar.O(':prec<b=>', '%defined');
}

token infix:sym<=>         { <sym> <O('%assignment, :pasttype<copy>')> }

token prefix:sym<defined?> { <sym> <O('%defined')> }

token infix:sym<+=>        { <sym> <O('%assignment')> }

token infix:sym<-=>        { <sym> <O('%assignment')> }

token infix:sym</=>        { <sym> <O('%assignment, :pirop<div>')> }

token infix:sym<*=>        { <sym> <O('%assignment, :pirop<mul>')> }

token infix:sym<%=>        { <sym> <O('%assignment, :pirop<mul>')> }

token infix:sym<|=>        { <sym> <O('%assignment')> }

token infix:sym<&=>        { <sym> <O('%assignment')> }

token infix:sym<~=>        { <sym> <O('%assignment')> }

token infix:sym«>>=»        { <sym> <O('%assignment, :pirop<shr>')> }

token infix:sym«<<=»        { <sym> <O('%assignment, :pirop<shl>')> }

token infix:sym<&&=>        { <sym> <O('%assignment, :pirop<and>')> }

token infix:sym<**=>        { <sym> <O('%assignment, :pirop<pow>')> }

token infix:sym<? :>        { <sym> <O('%ternary, :reducecheck<ternary>, :pasttype<if>')> }

token infix:sym<..>         { <sym> <O('%dotdot')> }

token infix:sym<...>        { <sym> <O('%dotdot')> }

token infix:sym<||>         { <sym> <O('%or, :pasttype<unless>')> }

token infix:sym<&&>         { <sym> <O('%and, :pasttype<if>')> }

token infix:sym<==>         { <sym> <O('%equality')> }
token infix:sym<!=>         { <sym> <O('%equality')> }
token infix:sym<=~>         { <sym> <O('%equality')> }
token infix:sym<!~>         { <sym> <O('%equality')> }
token infix:sym<===>        { <sym> <O('%equality')> }
token infix:sym«<=>»        { <sym> <O('%equality')> }

token infix:sym«>»          { <sym> <O('%cmp')> }
token infix:sym«<»          { <sym> <O('%cmp')> }
token infix:sym«<=»         { <sym> <O('%cmp')> }
token infix:sym«>=»         { <sym> <O('%cmp')> }

token infix:sym<|>          { <sym> <O('%bor')> }
token infix:sym<^>          { <sym> <O('%bor')> }

token infix:sym<&>          { <sym> <O('%band')> }

token infix:sym«<<»         { <sym> <O('%bsh')> }
token infix:sym«<>»         { <sym> <O('%bsh')> }

token infix:sym<+>          { <sym> <O('%plusminus')> }
token infix:sym<->          { <sym> <O('%plusminus')> }

token infix:sym<*>          { <sym> <O('%muldiv')> }
token infix:sym</>          { <sym> <O('%muldiv')> }
token infix:sym<%>          { <sym> <O('%muldiv, :pirop<mod>')> }

#token 'prefix:+' is tighter('infix:*')  { ... }
#token 'prefix:-' is equiv('prefix:+')  { ... }
#token 'prefix:!' is equiv('prefix:+')  { ... }
#token 'prefix:~' is equiv('prefix:+')  { ... }

#TODO
#token 'term:'   is tighter('infix:*')
#                is parsed(&primary)     { ... }

#token 'circumfix:( )' is equiv('term:') { ... }
