# Copyright (C) 2001-2008, Parrot Foundation.
# $Id$

=head1 TITLE

File - Cardinal File class

=head1 DESCRIPTION

=head2 Functions

=over

=item onload()

Perform initializations and create the File class

=cut

.namespace ['CardinalFile']

.sub 'onload' :anon :init :load
    $P0 = loadlib 'file'
    .local pmc cardinalmeta
    $P0 = get_hll_global ['CardinalObject'], '!CARDINALMETA'
    cardinalmeta = $P0.'new_class'('CardinalFile', 'parent'=>'parrot;File IO CardinalObject', 'attr'=>'!path')
    $P0.'register'('File', 'parent'=>'CardinalObject', 'protoobject'=>cardinalmeta)
    # XXX Throw some sort of runtime exception unless loadlib succeeded
    $P1 = loadlib 'os'
.end

.sub 'get_bool' :vtable
    .return (1)
.end

.sub 'ACCEPTS' :method
    .param pmc topic
    .local int i

    .local string what
    what = topic.'WHAT'()
    if what == "CardinalFile" goto match
    goto no_match
    no_match:
        $P0 = get_hll_global 'false'
        .return($P0)
    match:
        $P0 = get_hll_global 'true'
        .return($P0)
.end

#.sub 'get_string_keyed' :vtable
#   $S0 = 'File'
#   .return ($S0)
#.end

.namespace['File']

.sub 'open' :method
        .param pmc path
        .param string mode :optional
        .param pmc block :optional :named('!BLOCK')
        .local pmc cardinalmeta, this
        cardinalmeta = get_hll_global ['CardinalObject'], '!CARDINALMETA'
        $P0 = cardinalmeta.'get_parrotclass'(self)
        this = $P0.'new'()
        $S0 = this.'!to_path'(path)
        $P0 = this.'initialize'(path, mode)
        $I0 = defined block
        if $I0 == 1 goto exec_block
        goto done
        exec_block:
                getattribute $P1, this, '!io'
                block(this)
                close $P1
                $P2 = get_hll_global 'nil'
                .return ($P2)
        done:
        .return (this)
.end

.sub 'initialize' :method
        .param pmc path
        .param string mode :optional
        .local string parrot_io_mode
        .local pmc jmpstack
        jmpstack = new 'ResizableIntegerArray'

        $S0 = self.'!to_path'(path)
        local_branch jmpstack, parse_mode
        open $P1, $S0, parrot_io_mode
        #setprop self, '!io', $P0
        setattribute self, '!io', $P1
        #setprop self, '!path', path

        setattribute self, '!path', path
        goto done
        parse_mode:
                unless mode goto default_mode
                eq mode, "r", default_mode
                eq mode, "w", write_mode
                #eq mode, "r+", read_write_mode
                #eq mode, "a", append_mode
                goto done
        default_mode:
                parrot_io_mode = "<"
                local_return jmpstack
        append_mode:
                parrot_io_mode = ">>"
                local_return jmpstack
        write_mode:
                parrot_io_mode = ">"
                local_return jmpstack
        done:
                .return (self)
.end

.sub '!to_path' :method
        .param pmc path
        $S0 = typeof path
        cmp $I0, $S0, "CardinalString"
        if $I0 == 0 goto have_path
        goto get_path
        get_path:
            path = path.'to_path'()
            goto have_path
        have_path:
            $S0 = path
            .return ($S0)
        no_path:
            #TODO probably should throw an exception
            $S0 = ""
            .return ($S0)
.end

.include 'hllmacros.pir'
.include 'cclass.pasm'
.sub 'read' :method
        .local pmc io
        #getprop io, '!io', self
        getattribute io, self, '!io'
        #readline, read, peek
        $P0 = new 'CardinalString'
        readline $S0, io
        .While( { $S0 != '' },
        {
            $P0 = $P0.'concat'($S0)
            #$P0 = $P0.'concat'(.CCLASS_NEWLINE)
            readline $S0, io
        })
        .return ($P0)
.end

.sub 'puts' :method
        .param pmc args
        .local pmc io
        #getprop io, '!io', self
        getattribute io, self, '!io'
        print io, args
.end

.sub 'class' :method
        $P0 = new 'CardinalString'
        $S0 = "File"
        $P0.'concat'($S0)
        .return ($P0)
.end

.sub 'path' :method
        .local pmc path
        path = new 'CardinalString'
        #getprop path, '!path', self
        getattribute path, self, '!path'
        .return (path)
.end

.sub 'stat' :method
        .local pmc stat
        stat = new 'FileStat'
        $P0 = self.'path'()
        stat.'initialize'($P0)
        .return(stat)
.end

.sub 'exist?' :method
        .param string path
        $I0 = 0
        $I1 = stat path, $I0
        if $I1 == 1 goto yes
        goto no
        yes:
            $P0 = get_hll_global 'true'
            .return ($P0)
        no:
            $P0 = get_hll_global 'false'
            .return ($P0)
.end

.sub 'exists?' :method
        .param string path
        .local pmc exists
        exists = self.'exist?'(path)
        .return (exists)
.end

.sub 'unlink' :method
        .param pmc file_names :slurpy
        .local pmc os
        $P0 = iter file_names
        os = new 'OS'
        loop:
            unless $P0 goto done
            $S0 = shift $P0
            os.'rm'($S0)
            #unlink $S0 #does the unlink op code exist? should I use it?
            goto loop
         done:
.end

.sub 'delete' :method
        .param pmc file_names :slurpy
        self.'unlink'(file_names :flat)
.end


# Local Variables:
#   mode: pir
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4 ft=pir:
