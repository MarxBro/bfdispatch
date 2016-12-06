#!/usr/bin/perl
######################################################################
# Bf : Compilador de brainfuck
######################################################################

use strict;
use Data::Dumper "Dumper";
use feature "say";
use File::Slurp "read_file";

my $debug = 1;
$|++;

my $input_archivo = $ARGV[0]
  || die 'error: no se paso un archivo en la entrada';
my $input = read_file($input_archivo);
$input =~ s/[^\<\>\+\-\,\.\[\]]//g;

my @TAPE = (0);
my @CODE = split( "", $input );
print Dumper(@CODE) if $debug;

my $PUNTERO_TAPE    = 0;
my $codigo_posicion = 0;
my $old_pos_code;
my @RESULTADO = ();
my %shitcorch;

my $inputo = $ARGV[1] || " ";
my @INPUTOS = split("",$inputo);
my $INPUTOS_PUNTERO = 0;


######################################################################
# MAIN LOOP THINGY
######################################################################
my $hacer_para = {
    '>' => \&mv_cbz_der, 
    '<' => \&mv_cbz_izq, 
    '+' => \&puntero_pp, 
    '-' => \&puntero_mm, 
    '.' => \&print_puntero, 
    ',' => \&replace_puntero, 
    '[' => \&loop_start, 
};

while ( $codigo_posicion <= $#CODE + 1 ) {
    my $mod_256 = $TAPE[$PUNTERO_TAPE] % 256;
    $TAPE[$PUNTERO_TAPE] = $mod_256;
    my $espacio = $PUNTERO_TAPE % 4000;
    $PUNTERO_TAPE = $espacio;

    defined $hacer_para->{ $CODE[$codigo_posicion] }
      && $hacer_para->{ $CODE[$codigo_posicion] }->();

    say "código: $CODE[$codigo_posicion]"   if $debug;
    say "posicion codigo: $codigo_posicion"  if $debug;
    say "TAPE pos: $PUNTERO_TAPE"            if $debug;
    say "CURRENT TAPE: $TAPE[$PUNTERO_TAPE]" if $debug;
    say "-----------"                        if $debug;
    
    if ( $CODE[$codigo_posicion] eq ']' ) {
        $codigo_posicion = $old_pos_code if ( $TAPE[$PUNTERO_TAPE] != 0 );
    }
    
    $codigo_posicion++;
    select( undef, undef, undef, 0.2 ) if $debug;

}

print Dumper(@TAPE) if $debug;
print join('',@RESULTADO);
say "----";
exit;



######################################################################
# Subs
######################################################################
sub mv_cbz_der {
    $PUNTERO_TAPE++;
    $TAPE[$PUNTERO_TAPE] = 0 unless ( exists( $TAPE[$PUNTERO_TAPE] ) );
    return 1;
}

sub mv_cbz_izq {
    $PUNTERO_TAPE-- unless ( $PUNTERO_TAPE < 0 );
    return 1;
}

sub puntero_pp {
    $TAPE[$PUNTERO_TAPE]++;
    return 1;
}

sub puntero_mm {
    $TAPE[$PUNTERO_TAPE]--;
    return 1;
}

sub print_puntero {
    use bytes;
    push( @RESULTADO, chr($TAPE[$PUNTERO_TAPE]));
    no bytes;
    return 1;
}

sub replace_puntero {
    my $innie = ord($INPUTOS[$INPUTOS_PUNTERO]);
    $INPUTOS_PUNTERO++;
    if ($innie) {
        $TAPE[$PUNTERO_TAPE] = $innie;
        return 1;
    }
}

# Loops
sub loop_start {
    $old_pos_code = $codigo_posicion;
    if ( $TAPE[$PUNTERO_TAPE] == 0 ) {
        $codigo_posicion = buscar_code(']');
    }
    return 1;
}

sub buscar_code {
    my $num_corch            = 1;
    my $actual_posicion_code = $codigo_posicion;
            $shitcorch{$num_corch} = $actual_posicion_code;
    $actual_posicion_code++;
    while (1) {
        if ( $CODE[$actual_posicion_code] eq '[' ) {
            $num_corch++;
        }
        if ( $CODE[$actual_posicion_code] eq ']' && $num_corch == 1 ) {
            last;
        } elsif ( $CODE[$actual_posicion_code] eq ']' && $num_corch != 1 ) {
            $num_corch--;
        }
        $actual_posicion_code++;
    }
    $actual_posicion_code++;
    return $actual_posicion_code;
}

__DATA__
Referencias (gracias esolang!).

> 	increment the data pointer (to point to the next cell to the right).
< 	decrement the data pointer (to point to the next cell to the left).
+ 	increment (increase by one) the byte at the data pointer.
- 	decrement (decrease by one) the byte at the data pointer.
. 	output the byte at the data pointer.
, 	accept one byte of input, storing its value in the byte at the data pointer.
[ 	if the byte at the data pointer is zero, then instead of moving the instruction pointer forward to the next command, jump it forward to the command after the matching ] command.
] 	if the byte at the data pointer is nonzero, then instead of moving the instruction pointer forward to the next command, jump it back to the command after the matching [ command.


