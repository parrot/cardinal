class cardinal::Compiler is HLL::Compiler;

INIT {
    cardinal::Compiler.language('cardinal');
    cardinal::Compiler.parsegrammar(cardinal::Grammar);
    cardinal::Compiler.parseactions(cardinal::Actions);
}
