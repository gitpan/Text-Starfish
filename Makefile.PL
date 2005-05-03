use ExtUtils::MakeMaker;

# $Id: Makefile.PL,v 3.12 2005/04/27 13:17:55 vlado Exp $

WriteMakefile(
    'NAME'		=> 'Text::Starfish',
    'ABSTRACT'          => 'Perl-based Framework for '.
	                   'Text-Embedded Programming and Preprocessing',
    'VERSION_FROM'	=> 'Starfish.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
       (
      #ABSTRACT_FROM => 'Starfish.pm', # retrieve abstract from module
       AUTHOR     => 'Vlado Keselj www.cs.dal.ca/~vlado') : ()),
    'dist'  => {'COMPRESS'=>'gzip', 'SUFFIX' => 'gz'},
    'clean' => {FILES => "tmp* Text *~"}
    ,EXE_FILES => [ 'starfish' ]
);

# private parts of Makefile
open(M, ">>Makefile") or die;
if ( -f 'priv.make' ) { print M getfile('priv.make') }
close(M);

sub getfile($) {
    my $f = shift;
    local *F;
    open(F, "<$f") or die "getfile:cannot open $f:$!";
    my @r = <F>;
    close(F);
    return wantarray ? @r : join ('', @r);
}
