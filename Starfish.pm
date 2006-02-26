# (c) 2001-2006 Vlado Keselj www.cs.dal.ca/~vlado
#
# Starfish.pm and starfish - a Perl-based System for Text-Embedded
#     Programming and Preprocessing
#
# See the documentation following the code.  You can also use the
# command "perldoc Starfish.pm".

package Text::Starfish;
use strict;
use Carp;
use Cwd;
use POSIX;

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS); # Exporter vars
our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw(echo file_modification_date file_modification_time
		 read_starfish_conf last_update);
our $VERSION = '1.03';

use vars qw($Version $Revision);
$Version = $VERSION;
($Revision = substr(q$Revision: 3.43 $, 10)) =~ s/\s+$//;

use vars @EXPORT_OK;

# non-exported package globals go here
use vars qw();

# exported stuff (this should be handled by Exporter, but for some reason
# it does not work as it should.
sub echo($@);       sub main::echo($@);       *::echo = \&echo;
sub getfile($ );    sub main::getfile($ );    *::getfile = \&getfile;
sub putfile($@);    sub main::putfile($@);    *::putfile = \&putfile;
sub appendfile($@); sub main::appendfile($@); *::appendfile = \&appendfile;
sub getmakefilelist($$); sub main::getmakefilelist($$);
                                     *::getmakefilelist = \&getmakefilelist;
sub htmlquote($);   sub main::htmlquote($);   *::htmlquote = \&htmlquote;
sub read_records($); sub main::read_records($); *::read_records = \&read_records;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};

    # Initialization stuff
    # e.g. $self->{end} = '';

    # These may be set in starfish by command line options
    # no need to initialize
    # OUTFILE INITIAL_CODE REPLACE NEW_FILE_MODE
    #
    # Name other fields:
    # $IN_FILE $OUT_FILE @GLOBHOOK(not used, TODO maybe)
    # %FORBID_MACRO %MACRO_KEY

    bless($self, $class);
    return $self;
}

sub run {
    my $self = shift;
    my @args = @_;

    # @GlobHook = ();

    if (defined $self->{NEW_FILE_MODE}) {
	$self->{NEW_FILE_MODE} = oct($self->{NEW_FILE_MODE}) if $self->{NEW_FILE_MODE} =~ /^0/;
    }

    if (defined $self->{REPLACE} and !defined $self->{OUTFILE})
    { _croak("Starfish:output file required for replace") }

    my $FileCount=0;
    $self->{Loops} = 1;

    $self->eval1($self->{INITIAL_CODE}, 'initial');

    while (@args) {
	$self->{INFILE} = shift @args;
	my $InFile = $self->{INFILE};
	++$FileCount;

	$self->{CurrentLoop} = 1;
	if (!defined $self->{STYLE}) {
	    my $f = $InFile;
	    $f =~ s/\.s(tar)?fish$//;
	    if    ($f =~ /\.html?/i)       { $self->setStyle('html') }
	    elsif ($f =~ /\.(?:la)?tex$/i) { $self->setStyle('tex') }
	    elsif ($f =~ /\.java$/i)       { $self->setStyle('java') }
	    elsif ($f =~ /^[Mm]akefile/)   { $self->setStyle('makefile') }
	    elsif ($f =~ /\.ps$/i)         { $self->setStyle('ps') }
	    elsif ($f =~ /\.py$/i)         { $self->setStyle('python') }
	    else { $self->setStyle('perl') }
	} else { $self->setStyle($self->{STYLE}) }

	undef $self->{macrosdefine};
	undef $self->{Macros};
	undef $self->{ForbidMacro};

	# take all data into $self->{data}
	$self->{data} = getfile $InFile;

	my $ExistingText;
	if (! defined $self->{OUTFILE}) {
	    $ExistingText = $self->{data};
	    $self->{LastUpdateTime} = (stat $InFile)[9];
	}
	elsif ($FileCount > 1)  {
	    $ExistingText = '';
	    $self->{LastUpdateTime} = time;
	}
	elsif (! -f $self->{OUTFILE})   {
	    $ExistingText = '';
	    $self->{LastUpdateTime} = time;
	}
	else {
	    $ExistingText = getfile $self->{OUTFILE};
	    $self->{LastUpdateTime} = (stat $self->{OUTFILE})[9];
	}

      START:
	$self->{Out} = '';
	$self->scan();
	while ($self->{ttype} != -1) {
	    if ($self->{ttype} > -1 ) {	                        # call evaluator
		$self->{Out}.= &{$self->{hook}->[$self->{ttype}]->{f}}
		( $self, $self->{prefix}, $self->{currenttoken}, $self->{suffix});
	    }
	    else { $self->{Out}.=$self->{currenttoken} }
	    $self->scan();
	}

	if ($self->{CurrentLoop} < $self->{Loops}) {
	    ++$self->{CurrentLoop};
	    $self->{data} = $self->{Out};
	    if ($ExistingText ne $self->{Out})
	    { $self->{LastUpdateTime} = time }
	    goto START;
	}

	if (defined $self->{macrosdefined}) {
	    my ($m, $s);
	    while (($m,$s) = each %{$self->{Macros}}) {
		if ($s =~ /\n/) {
		    my $p1 = "$`$&"; $s = $';
		    if ($s) { $s = $p1.wrap($s) }
		    else { $s = $p1 }
		}
		$self->{Out}.= $self->{MprefAuxDefine}.$s.$self->{MsufAuxDefine};
	    }
	}

	if ($FileCount==1 && defined $self->{OUTFILE}) {
	    # touch the outfile if it does not exist
	    if ( ! -f $self->{OUTFILE} ) {
		putfile $self->{OUTFILE};
		if (defined $self->{NEW_FILE_MODE}) { chmod $self->{NEW_FILE_MODE}, $self->{OUTFILE}}
		else                      { chmod ((stat $InFile)[2]), $self->{OUTFILE}}
	    }
	    elsif  (defined $self->{NEW_FILE_MODE}) { chmod $self->{NEW_FILE_MODE}, $self->{OUTFILE} }
	}

	# write the text if changed
	if ($ExistingText ne $self->{Out}) {
	    if (defined $self->{OUTFILE}) {
		# If the OutFile is defined, we may have to play with
		# permissions in order to write.  Be careful! Allow
		# unallowed write only on outfile and if -mode is
		# specified
		my $mode = ((stat $self->{OUTFILE})[2]);
		if (($mode & 0200) == 0 and defined $self->{NEW_FILE_MODE}) {
		    chmod $mode|0200, $self->{OUTFILE};
		    if ($FileCount==1) { putfile $self->{OUTFILE}, $self->{Out} }
		    else            { appendfile $self->{OUTFILE}, $self->{Out} }
		    chmod $mode, $self->{OUTFILE};
		} else {
		    if ($FileCount==1) { putfile $self->{OUTFILE}, $self->{Out} }
		    else            { appendfile $self->{OUTFILE}, $self->{Out} }
		}
	    }
	    else {
		putfile $InFile, $self->{Out};
		chmod $self->{NEW_FILE_MODE}, $InFile if defined $self->{NEW_FILE_MODE};
	    }
	}
	elsif (defined $self->{NEW_FILE_MODE}) {
	    if (defined $self->{OUTFILE}) { chmod $self->{NEW_FILE_MODE}, $self->{OUTFILE} }
	    else                  { chmod $self->{NEW_FILE_MODE}, $InFile }
	}
    }				# end of while (@args)

}				# end of sub run

sub _index {
    my $str = shift;
    my $subs = shift;
    if (ref($subs) eq 'Regexp') {
	if ($str =~ $subs) { return (length($`),length($&)) }
	else { return (-1,0) }
    }
    else { return (index($str, $subs), length($subs)) }
}

# $self->{ttype}: -1 EOF
#             -2 outer text
sub scan {
    my $self = shift;

    $self->{prefix} = $self->{suffix} = '';
    if ($self->{data} eq '') {	# no more data, EOF
	$self->{ttype} = -1;
	$self->{currenttoken} = '';
    }
    else {
	my $i1 = length($self->{data}) + 1;
	my $pl=0; my $i2=$i1; my $sl=0;
	$self->{ttype} = -2;
	foreach my $ttype (0 .. $#{ $self->{hook} }) {
	    my ($j, $pl2, $j2, $sl2);
	    my ($j,$pl2) = _index($self->{data}, $self->{hook}->[$ttype]->{'begin'});
	    next unless $j != -1 && $j <= $i1;
	    my $data2 = substr($self->{data}, $j);
	    if ($self->{hook}->[$ttype]->{'end'} ne '') {
		($j2, $sl2) = _index($data2, $self->{hook}->[$ttype]->{'end'});
		next if -1 == $j2;
		$j2 += $j;
	    } else { $j2 = length($self->{data}) + 1; $sl2 = 0; }
	    $i1 = $j; $pl = $pl2; $i2 = $j2; $sl = $sl2; $self->{ttype} = $ttype;
	}

	if ($self->{ttype}==-2) {$self->{currenttoken}=$self->{data}; $self->{data}=''}
	else {
	    $self->{Out} .= substr($self->{data}, 0, $i1); # just copy type -2
                            # instead of returning as earlier, to
	                    # support negative look-back for prefix
	    $self->{prefix} = substr($self->{data}, $i1, $pl);
	    $self->{currenttoken} = substr($self->{data}, $i1+$pl, $i2-$i1-$pl);
	    $self->{suffix} = substr($self->{data}, $i2, $sl);
	    $self->{data} = substr($self->{data}, $i2+$sl);
	}
	# vlado: this should be delete at some point, 2006-02-25
	#elsif ($i1 > 0) {
	#    $self->{currenttoken} = substr($self->{data}, 0, $i1);
	#    $self->{data} = substr($self->{data}, $i1);
	#    $self->{ttype} = -2;
	#} else {
	#    $self->{prefix} = substr($self->{data}, 0, $pl);
	#    $self->{currenttoken} = substr($self->{data}, $i1+$pl, $i2-$i1-$pl);
	#    $self->{suffix} = substr($self->{data}, $i2, $sl);
	#    $self->{data} = substr($self->{data}, $i2+$sl);
	#}
    }

    return $self->{ttype};
}

# eval wrapper
sub eval1 {
    my $self = shift;

    my $code = shift;
    my $comment = shift;
    eval("package main; no strict; $code");
    if ($@) {
	my ($code1, $linecnt);
	foreach (split(/\n/, $code))
	{ ++$linecnt; $code1 .= sprintf("%03d %s\n", $linecnt, $_); }
	_croak("$comment code error:$@\ncode:\n$code1");
    }
}

########################################################################
# The main subroutine for evauating a snippet
#
sub evaluate {
    my $self = shift;

    my $pref = shift;
    my $code = shift; my $c = $code;
    my $suf = shift;
    if (defined($self->{CodePreparation}) && $self->{CodePreparation}) {
	local $_=$code;
	$self->eval1($self->{CodePreparation},'preprocessing');
	$code = $_;
  	}

    # Evaluate code, first final preparation and then eval1
    $::O = '';
    $::Star = $self;
    $self->eval1($code, 'snippet');
 
    if ($self->{REPLACE}) { return $::O }
    #
    # $self->{hook}->[0] is reserved for output pieces
    #
    if ($::O ne '') { $suf.="$self->{hook}->[0]->{'begin'}$::O$self->{hook}->[0]->{'end'}" }
    return "$pref$c$suf";
}

# Python-specific evaluator
sub evaluate_py {
    my $self = shift;

    my $pref = shift;
    my $code = shift; my $c = $code;
    my $suf = shift;
    if (defined($self->{CodePreparation}) && $self->{CodePreparation}) {
	local $_=$code;
	$self->eval1($self->{CodePreparation},'preprocessing');
	$code = $_;
    }

    # Evaluate code, first final preparation and then eval1
    $::O = '';
    $::Star = $self;
    $self->eval1($code, 'snippet');
 
    if ($self->{REPLACE}) { return $::O }
    if ($::O ne '') {
	my $indent = '';
	if ($c =~ /^(\s+)#/m) { $indent = $1 }
	$suf .= "\n".$indent."#+\n".$::O.
	        "\n".$indent."#-\n";
    }
    return "$pref$c$suf";
}

# a predefined evaluator
sub eval_ignore {
    my $self = shift;
    return '' if $self->{REPLACE};

    my $pref = shift;
    my $code = shift;
    my $suf = shift;
    return $pref.$code.$suf;
}

sub define {
    my $self = shift;

    my $pref = shift;
    my $data = shift;
    my $suf = shift;

    if ($self->{CurrentLoop} > 1) { return "$pref$data$suf"; }

    $data =~ /^.+/ or _croak("expected macro spec");
    _croak("no macro spec") unless $&;
    _croak("double macro def (forbidden):$&") if ($self->{ForbidMacro}->{$&});
    $self->{Macros}->{$&} = $data;
    return '';
}

sub MCdefine {
    my $self = shift;
    my $pref = shift;
    my $data = shift;
    my $suf = shift;

    if ($self->{CurrentLoop} > 1) { die "define in loop > 1 !?" }

    $data =~ /^.+/ or die "expected macro spec";
    die "no macro spec" unless $&;
    die "double macro def (forbidden):$&" if ($self->{ForbidMacro}->{$&});
    $self->{Macros}->{$&} = $data;
    return '';
}

sub MCdefe {
    my $self = shift; die "(".ref($self).")" unless ref($self) eq 'Text::Starfish';

    my $pref = shift;
    my $data = shift;
    my $suf = shift;

    if ($self->{CurrentLoop} > 1) { die "defe in a loop >1!?" }

    $data =~ /^.+/ or die "expected macro spec";
    die "no macro spec" unless $&;
    die "def macro forbidden:$&\n" if (defined $self->{ForbidMacro}->{$&});
    $self->{Macros}->{$&} = $data;
    return $self->{MacroKey}->{'expand'}.$&.$self->{MacroKey}->{'/expand'};
}

sub MCnewdefe {
    my $self = shift; die "(".ref($self).")" unless ref($self) eq 'Text::Starfish';

    my $pref = shift;
    my $data = shift;
    my $suf = shift;

    if ($self->{CurrentLoop} > 1) { die "newdefe in second loop!?" }

    $data =~ /^.+/ or die "expected macro spec";
    die "no macro spec" unless $&;
    if (defined $self->{Macros}->{$&} || $self->{ForbidMacro}->{$&}) {
	die "double def:$&" }
    $self->{Macros}->{$&} = $data;
    $self->{ForbidMacro}->{$&} = 1;
    return $self->{MprefExpand}.$&.$self->{MsufExpand};
}

sub expand {
    my $self = shift; die "(".ref($self).")" unless ref($self) eq 'Text::Starfish';

    my $pref = shift;
    my $data = shift;
    my $suf = shift;

    if ($self->{CurrentLoop} < 2 || $self->{HideMacros})
    { return $self->{MacroKey}->{'expand'}.$data.$self->{MacroKey}->{'/expand'} }
    
    $data =~ /^.+/ or die "expected macro spec";
    die "no macro spec" unless $&;
    return $self->{MacroKey}->{'expanded'}.$self->{Macros}->{$&}.$self->{MacroKey}->{'/expanded'};
}

sub MCexpand {
    my $self = shift; die "(".ref($self).")" unless ref($self) eq 'Text::Starfish';

    my $pref = shift;
    my $data = shift;
    my $suf = shift;

    if ($self->{CurrentLoop} < 2 || $self->{HideMacros}) { return "$pref$data$suf"; }
    
    $data =~ /^.+/ or die "expected macro spec";
    die "no macro spec" unless $&;
    die "macro not defined" unless defined $self->{Macros}->{$&};
    return $self->{MprefExpanded}.$self->{Macros}->{$&}.$self->{MsufExpanded};
}

sub fexpand {
    my $self = shift; die "(".ref($self).")" unless ref($self) eq 'Text::Starfish';

    my $pref = shift;
    my $data = shift;
    my $suf = shift;

    if ($self->{CurrentLoop} < 2) { return "$pref$data$suf"; }
    
    $data =~ /^.+/ or die "expected macro spec";
    die "no macro spec" unless $&;
    die "macro not defined:$&" unless defined $self->{Macros}->{$&};
    return $self->{MpreffExpanded} . $self->{Macros}->{$&}.$self->{MsuffExpanded};
}

sub MCfexpand {
    my $self = shift; die "(".ref($self).")" unless ref($self) eq 'Text::Starfish';

    my $pref = shift;
    my $data = shift;
    my $suf = shift;

    if ($self->{CurrentLoop} < 2) { return "$pref$data$suf"; }
    
    $data =~ /^.+/ or die "expected macro spec";
    die "no macro spec" unless $&;
    die "macro not defined:$&" unless defined $self->{Macros}->{$&};
    return $self->{MacroKey}->{'fexpanded'}.$self->{Macros}->{$&}.$self->{MacroKey}->{'/fexpanded'};
}

sub expanded {
    my $self = shift; die "(".ref($self).")" unless ref($self) eq
	'Text::Starfish';

    my $pref = shift;
    my $data = shift;
    my $suf = shift;
    
    $data =~ /^.+/ or die "expected macro name";
    die "no macro spec" unless $&;
    return $self->{MprefExpand}.$&.$self->{MsufExpand};
}

sub MCexpanded {
    my $self = shift; die "(".ref($self).")" unless ref($self) eq
	'Text::Starfish';

    my $pref = shift;
    my $data = shift;
    my $suf = shift;
    
    $data =~ /^.+/ or die "expected macro name";
    die "no macro spec" unless $&;
    return $self->{MacroKey}->{'expand'}.$&.$self->{MacroKey}->{'/expand'};
}

sub fexpanded {
    my $self = shift; die "(".ref($self).")" unless ref($self) eq
	'Text::Starfish';

    my $pref = shift;
    my $data = shift;
    my $suf = shift;
    
    $data =~ /^.+/ or die "expected macro name";
    die "no macro spec" unless $&;
    return $self->{MpreffExpand}.$&.$self->{MsuffExpand};
}

sub MCfexpanded {
    my $self = shift; die "(".ref($self).")" unless ref($self) eq
	'Text::Starfish';

    my $pref = shift;
    my $data = shift;
    my $suf = shift;
    
    if ($self->{CurrentLoop} < 2) { return "$pref$data$suf"; }
    $data =~ /^.+/ or die "expected macro name";
    die "no macro spec" unless $&;
    die "Macro not defined:$&" unless defined $self->{Macros}->{$&};
    return $self->{MacroKey}->{'fexpanded'}.$self->{Macros}->{$&}.$self->{MacroKey}->{'/fexpanded'};
}

sub MCauxdefine {
    my $self = shift; die "(".ref($self).")" unless ref($self) eq
	'Text::Starfish';

    my $pref = shift;
    my $data = shift;
    my $suf = shift;
    
    $data =~ /^.+/ or die "expected macro name";
    die "no macro spec" unless $&;
    my $mn = $&;
    $data = unwrap($data);
    die "double macro def (forbidden):$mn\n" if ($self->{ForbidMacro}->{$mn});
    if (! defined($self->{Macros}->{$mn}) ) { $self->{Macros}->{$mn}=$data }
    return '';
}

sub auxDefine {
    my $self = shift; die "(".ref($self).")" unless ref($self) eq
	'Text::Starfish';

    my $pref = shift;
    my $data = shift;
    my $suf = shift;
    
    $data =~ /^.+/ or die "expected macro name";
    die "no macro spec" unless $&; my $mn = $&;
    $data = unwrap($data);
    die "double macro def (forbidden):$mn\n" if ($self->{ForbidMacro}->{$mn});
    if (! defined($self->{Macros}->{$mn}) ) { $self->{Macros}->{$mn}=$data }
    return '';
}

sub wrap {
    my $d = shift;
    $d =~ s/^/\/\/ /mg;
    return $d;
}

sub unwrap {
    my $d = shift;
    $d =~ s/^\/\/ //mg;
    return $d;
}

sub setGlobStyle {
    my $self = shift;
    my $s = shift;
    $self->{STYLE} = $s;
    $self->setStyle($s);
}

sub setStyle {
    my $self = shift;

    my $s = shift;
    if ($s eq 'latex' or $s eq 'TeX') {	$s = 'tex' }
    if ($s eq $self->{Style}) { return }
    
    # default
    $self->{'LineComment'} = '#';
    $self->{hook}= [
      {begin => "\n#+\n", end=>"\n#-\n", f=>sub{return''}}, # Reserved for output
      {begin => '<?', end => '!>', f => \&evaluate },
      {begin => '<?starfish', end => '?>', f => \&evaluate }
    ];
    $self->{CodePreparation} = 's/\\n(?:#|%|\/\/+)/\\n/g';

    if ($s eq 'perl') { }
    elsif ($s eq 'makefile') { }
    elsif ($s eq 'java') {
	$self->{LineComment} = '//';
	$self->{hook} = [{begin => "//+\n", end=>"//-\n", f=>sub{return''}},  # Reserved for output
		 {begin => '<?', end => '!>', f => \&evaluate }];
	$self->{CodePreparation} = 's/^\s*\/\/+//mg';
    }
    elsif ($s eq 'tex') {
	$self->{LineComment} = '%';
	$self->{hook}=[{begin => "%+\n", end=>"\n%-\n", f=>sub{return''}},  # Reserved for output
	       {begin => '<?', end => "!>\n", f => \&evaluate }];
	$self->{CodePreparation} = 's/\\n(?:#|%+|\/\/+)/\\n/g';
    }
    elsif ($s eq 'python') {
	$self->{hook} =
	    [{begin => qr/\n\s*#\+\n/, end=>qr/\n\s*#-\n/, f=>sub{return''}}, # Reserved for output
	     {begin => '<?', end => '!>', f => \&evaluate_py },
	     {begin => '<?starfish', end => '?>', f => \&evaluate_py }
	     ];
	$self->{CodePreparation} = 's/\\n\\s*#/\\n/g';
    }
    elsif ($s eq 'html') {
	undef $self->{LineComment};
	$self->{hook}=[{begin => "\n<!-- + -->\n", end=>"\n<!-- - -->\n",   # Reserved for output
		f=>sub{return''}},
	       {begin => '<!--<?', end => '!>-->', f => \&evaluate },
	       #{begin=>'<?', end=>'?>', f=>\&evaluate },
	       {begin=>'<?starfish ', end=>'?>', f=>\&evaluate }
        ];
	$self->{CodePreparation} = '';
    }
    elsif ($s eq 'ps') {
	$self->{LineComment} = '%';
	$self->{hook}=[{begin => "\n% +\n", end=>"\n% -\n",   # Reserved for output
		f=>sub{return''}},
	       {begin => '<?', end => '!>', f => \&evaluate }];
	$self->{CodePreparation} = 's/\\n%/\\n/g';
    }
    else { _croak("setStyle:unknown style:$s") }
    $self->{Style} = $s;
}

sub addHook {
    my $self = shift;
    my $p = shift;
    my $s = shift;
    my $fun = shift;
    my @Hook = @{ $self->{hook} };
    if ($fun eq 'default')
    { push @Hook, {begin=>$p, end=>$s, f=>\&evaluate} }
    elsif ($fun eq 'ignore')
    { push @Hook, {begin=>$p, end=>$s, f=>\&eval_ignore} }
    elsif (ref($fun) eq 'CODE') {
	push @Hook, {begin=>$p, end=>$s,
		     f=> sub { local $_; my $self=shift;
			       my $p=shift; $_=shift; my $s=shift;
			       &$fun($p,$_,$s);
			       if ($self->{REPLACE}) { return $_ }
			       return "$p$_$s";
			   }
		 };
    }
    else {
	eval("push \@Hook, {begin=>\$p, end=>\$s,".
	     "f=>sub{\n".
	     "local \$_;\n".
	     "my \$self = shift;\n".
	     "my \$p = shift; \$_ = shift; my \$s = shift;\n".
	     "$fun;\n".
             'if ($self->{REPLACE}) { return $_ }'."\n".
             "return \"\$p\$_\$s\"; } };");
    }
    _croak("addHook error:$@") if $@;
    $self->{hook} = \@Hook;
}

sub rmHook {
    my $self = shift;
    my $p = shift;
    my $s = shift;
    my @Hook = @{ $self->{hook} };
    my @Hook1 = ();
    foreach my $h (@Hook) {
	if ($h->{begin} eq $p and $h->{end} eq $s) {}
	else { push @Hook1, $h }
    }
    $self->{hook} = \@Hook1;
}

sub rmAllHooks {
    my $self = shift;
    $self->{hook} = [];
}

sub defineMacros {
    my $self = shift;

    return if $self->{CurrentLoop} > 1;
    $self->{Loops} = 2 if $self->{Loops} < 2;
    $self->{MprefDefine} = '//define ';
    $self->{MsufDefine} = "//enddefine\n";
    $self->{MprefExpand} = '//expand ';
    $self->{MsufExpand} = "\n";
    $self->{MacroKey}->{'expand'}   = '//m!expand ';
    $self->{MacroKey}->{'/expand'} = "\n";
    $self->{MacroKey}->{'expanded'}  = '//m!expanded ';
    $self->{MacroKey}->{'/expanded'} = "//m!end\n";
    $self->{MpreffExpand} = '//fexpand ';
    $self->{MsuffExpand} = "\n";
    $self->{MacroKey}->{'fexpand'}   = '//m!fexpand ';
    $self->{MacroKey}->{'/fexpand'} = "\n";
    $self->{MprefExpanded} = '//expanded ';
    $self->{MsufExpanded} = "//endexpanded\n";
    $self->{MpreffExpanded} = '//fexpanded ';
    $self->{MsuffExpanded} = "//endexpanded\n";
    $self->{MacroKey}->{'fexpanded'}  = '//m!fexpanded ';
    $self->{MacroKey}->{'/fexpanded'} = "//m!end\n";
    $self->{MprefAuxDefine}='//auxdefine ';
    $self->{MsufAuxDefine}="//endauxdefine\n";
    $self->{MacroKey}->{'auxdefine'}='//m!auxdefine ';
    $self->{MacroKey}->{'/auxdefine'}="//m!endauxdefine\n";
    $self->{MacroKey}->{'define'} = '//m!define ';
    $self->{MacroKey}->{'/define'} = "//m!end\n";
    $self->{MacroKey}->{'defe'} = '//m!defe ';
    $self->{MacroKey}->{'/defe'} = "//m!end\n";
    $self->{MacroKey}->{'newdefe'} = '//m!newdefe ';
    $self->{MacroKey}->{'/newdefe'} = "//m!end\n";
    push @{$self->{hook}},
    {begin=>$self->{MprefDefine},    end=>$self->{MsufDefine}, f=>\&define},
    {begin=>$self->{MprefExpand},    end=>$self->{MsufExpand}, f=>\&expand},
    {begin=>$self->{MpreffExpand},   end=>$self->{MsuffExpand}, f=>\&fexpand},
    {begin=>$self->{MprefExpanded},  end=>$self->{MsufExpanded}, f=>\&expanded},
    {begin=>$self->{MpreffExpanded}, end=>$self->{MsuffExpanded},f=>\&fexpanded},
    {begin=>$self->{MprefAuxDefine}, end=>$self->{MsufAuxDefine},f=>\&auxDefine},
    {begin=>$self->{MacroKey}->{'auxdefine'},end=>$self->{MacroKey}->{'/auxdefine'},f=>\&MCauxdefine},
    {begin=>$self->{MacroKey}->{'define'},   end=>$self->{MacroKey}->{'/define'},  f=>\&MCdefine},
    {begin=>$self->{MacroKey}->{'expand'},   end=>$self->{MacroKey}->{'/expand'},  f=>\&MCexpand},
    {begin=>$self->{MacroKey}->{'fexpand'}, end=>$self->{MacroKey}->{'/fexpand'}, f=>\&MCfexpand},
    {begin=>$self->{MacroKey}->{'expanded'},end=>$self->{MacroKey}->{'/expanded'},f=>\&MCexpanded},
    {begin=>$self->{MacroKey}->{'fexpanded'},end=>$self->{MacroKey}->{'/fexpanded'},f=>\&MCfexpanded},
    {begin=>$self->{MacroKey}->{'defe'},    end=>$self->{MacroKey}->{'/defe'},    f=>\&MCdefe},
    {begin=>$self->{MacroKey}->{'newdefe'}, end=>$self->{MacroKey}->{'/newdefe'}, f=>\&MCnewdefe};
    $self->{macrosdefined} = 1;
}

sub getmakefilelist ($$) {
    my $f = getfile($_[0]); shift;
    my $l = shift;
    $f =~ /\b$l=(.*(?:(?<=\\)\n.*)*)/ or
	die "starfish:getmakefilelist:no list:$l";
    $f=$1; $f=~s/\\\n/ /g;
    $f =~ s/^\s+//; $f =~ s/\s+$//;
    return split(/\s+/, $f);
}

# Should be used for example
# e.g. addHookUnComment("\n%Dbegin", "\n%Dend");
#sub addHookUnComment {
#    my $t1 = shift;
#    my $t2 = shift;
#    addHook($t1, $t2, 's/\n%!/\n/g');
#}
#
#sub addHookComment {
#    my $t1 = shift;
#    my $t2 = shift;
#    addHook($t1, $t2, 's/\n(?:%!)?/\n%!/g');
#}

sub echo($@) { $::O .= join('', @_) }

sub getfile($) {
    my $f = shift;
    local *F;
    open(F, "<$f") or die "starfish:getfile:cannot open $f:$!";
    my @r = <F>;
    close(F);
    return wantarray ? @r : join ('', @r);
}

sub putfile($@) {
    my $f = shift;
    local *F;
    open(F, ">$f") or die "starfish:putfile:cannot open $f:$!";
    print F '' unless @_;
    while (@_) { print F shift(@_) }
    close(F)
}

sub appendfile($@) {
    my $f = shift;
    local *F;
    open(F, ">>$f") or die "starfish:appendfile:cannot open $f:$!";
    print F '' unless @_;
    while (@_) { print F shift(@_) }
    close(F)
}

sub htmlquote($) {
    local $_ = shift;
    s/&/&amp;/g;
    s/</&lt;/g;
    s/\"/&quot;/g;
    return $_;
}

sub read_records($ ) {
  my $arg = shift;
  if ($arg =~ /^file=/) { $arg = getfile($') }
  my $db = [];
  while ($arg) {
      $arg =~ s/^\s*(#.*\s*)*//;  # allow comments betwen records
      my $record;
      if ($arg =~ /\n\n+/) { $record = "$`\n"; $arg = $'; }
      else { $record = $arg; $arg = ''; }
      my $r = {};
      while ($record) {
	  if ($record =~ /^#.*\n/) { $record=$'; next; } # allow
                                                 #   comments in records		
        $record =~ /^([^\n:]*):/ or
	    croak "field not properly defined in record: ($record)";
	my $k = $1; $record = $'; my $v;
	while (1) {		# .................... line continuation
	    if ($record =~ /^(.*)\\(\n)/) { $v .= $1.$2; $record = $'; }
	    elsif ($record =~ /^(.*)\n[ \t]/)
	    { $v .= $1; $record = $'; }
	    elsif ($record =~ /^(.*)\n/)
	    { $v .= $1; $record = $'; last; }
	    else { $v .= $record; $record = ''; last }
	}
        if (exists($r->{$k})) {
          my $c = 0;
          while (exists($r->{"$k-$c"})) { ++$c }
          $k = "$k-$c";
        }
        $r->{$k} = $v;
      }
      push @{ $db }, $r;
  }
  return wantarray ? @{$db} : $db;
}

sub last_update() {
    my $self = @_ ? shift : $::Star;
    if ($self->{Loops} < 2) { $self->{Loops} = 2 }
    return POSIX::strftime("%d-%b-%Y", localtime($self->{LastUpdateTime}));
}

sub file_modification_time() {
    my $self = @_ ? shift : $::Star;
    return (stat $self->{INFILE})[9];
}

sub file_modification_date() {
    my $self = @_ ? shift : $::Star;

    my $t = $self->file_modification_time();
    my @a = localtime($t); $a[5] += 1900;
    return qw/January February March April May June July
    	      August September October November December/
		  [$a[4]]." $a[3], $a[5]";
}

sub read_starfish_conf() {
    return unless -e "starfish.conf";
    my @dirs = ( '.' );
    while ( -e "$dirs[0]/../starfish.conf" )
    { unshift @dirs, "$dirs[0]/.." }

    my $currdir = cwd();
    foreach my $d (@dirs) {
	chdir $d or die "cannot chdir to $d";
	package main;
	require "$currdir/$d/starfish.conf";
	package Text::Starfish;
	chdir $currdir or die "cannot chdir to $currdir";
    }
}

sub _croak {
    my $m = shift;
    require Carp;
    Carp::croak($m);
}

__END__
# Documentation
=pod

=head1 NAME

Text::Starfish.pm and starfish - A Perl-based System for Text-Embedded
      Programming and Preprocessing


=head1 SYNOPSIS

B<starfish> S<[ B<-o=>I<outputfile> ]> S<[ B<-e=>I<initialcode> ]>
        S<[ B<-replace> ]> S<[ B<-mode=>I<mode> ]> S<I<file>...>

where files usually contain some Perl code, delimited by C<E<lt>?> and
C<!E<gt>>.

=head1 DESCRIPTION

(The documentation is probably not up to date.)

Starfish is a system for Perl-based text-embedded programming and
preprocessing relying on a unifying regular expression rewriting
methodology.  If you know Perl and php, you probably know the basic
idea: embed Perl code inside the text, execute it is some way, and
interleave the output with the text.   Very similar projects exist and
some of them are listed in L<"SEE ALSO">.  Starfish is, however,
unique in several ways.

There are two files in this package: a module (Starfish.pm) and a
small script (starfish) that relies on the module.
The earlier name of this module was SLePerl (Something Like ePerl),
but it was changed it to C<starfish> -- sounds better and easier to
type.  One option was `oyster,' but some people are thinking
about using it for Perl beans, and there is a (yet another) Perl
module for embedded Perl C<Text::Oyster>, so it was not used.

The idea with the `C<starfish>' name is: the Perl code is embedded into
a text, so the text is equivalent to a shellfish containing pearls.
A starfish comes by and eats the shellfish...  Unlike a natural
starfish, this C<starfish> is interested in pearls and does not
normally touch most of the surrounding meat.


An important difference between C<starfish> and similar programs
(e.g. php) is: the output does not necessarily replace the code, it
follows the code by default.

To produce output to be inserted into the file, use variable C<$O> or
function C<echo>.

=head1 EXAMPLES

=head2 A simple example

A simple example, after running C<starfish> on a file containing:

     <? $O= "Hello world!" !>

we get the following output:

     <? $O= "Hello world!" !>
     #+
     Hello world!
     #-

The output will not change after running the script several times.
The same effect is achieved with:

     <? echo "Hello world! !>

The function echo simply appends its parameters to the special
variable $O.

Some parameters can be changed, and they vary according to style,
which depends on file extension.  Since the code is not stable, they
are not documented, but here is a list of some of them (possibly
incorrect):

 - code prefix and suffix (e.g., <? !> )
 - output prefix and suffix (e.g., \n#+\n \n#-\n )
 - code preparation (e.g., s/\\n(?:#+|%+\/\/+)/\\n/g )

=head2 HTML Examples

=head3 Example 1

If we have an HTML file, e.g., C<7.html> with the following
content:

  <HEAD>
  <BODY>
  <!--<? $O="This code should be replaced by this." !>-->
  </BODY>

then after running the command

  starfish -replace -o=7out.html 7.html

the file C<7out.html> will contain:

  <HEAD>
  <BODY>
  This code should be replaced by this.
  </BODY>

The same effect would be obtained with the following line:

  <!--<? echo "This code should be replaced by this." !>-->

=head3 Output file permissions

The permissions of the output file will not be changed.  But if it
does not exist, then:

  starfish -replace -o=7out.html -mode=0644 7.html

makes sure it has all-readable permission.

=head3 Example 2

Input file C<21.html>:

  <!--<? use CGI qw/:standard/;
         echo comment('AUTOMATICALLY GENERATED - DO NOT EDIT');
  !>-->
  <HTML><HEAD>
  <TITLE>Some title</TITLE>
  </HEAD>
  <BODY>
  <!--<? echo "Put this." !>-->
  </BODY>
  </HTML>

Output:

  <!-- AUTOMATICALLY GENERATED - DO NOT EDIT -->
  <HTML><HEAD>
  <TITLE>Some title</TITLE>
  </HEAD>
  <BODY>
  Put this.
  </BODY>
  </HTML>

=head2 Example from a Makefile
 
  LIST=first second third\
   fourth fifth

  <? echo join "\n", getmakefilelist $Star->{INFILE}, 'LIST' !>
  #+
  first
  second
  third
  fourth
  fifth
  #-

Beside $O, $Star is another predefined variable: It refers to the
Starfish object currently processing the text.

=head2 Example from a TeX file

 % <? $Star->Style('TeX') !>

 % For version 1 of a document
 % <? #$Star->addHook("\n%Begin1","\n%End1",'s/\n%+/\n/g');
 %    #$Star->addHook("\n%Begin2","\n%End2",'s/\n%*/\n%/g');
 %    #For version 2
 %    $Star->addHook("\n%Begin1","\n%End1",'s/\n%*/\n%/g');
 %    $Star->addHook("\n%Begin2","\n%End2",'s/\n%+/\n/g');
 % !>

 %Begin1
 %Document 1
 %End1

 %Begin2
 Document 2
 %End2

=head2 Example with Test/Release versions (Java)

Suppose you have a stanalone java file p.java, and you want to have
two versions:

  p_t.java -- for complete code with all kinds of testing code, and
  p.java -- clean release version.

Solution:

Copy p.java to p_t.java and modify p_t.java to be like:

  /** Some Java file.  */

  //<? $O = defined($Release) ?
  // "public class p {\n" :
  // "public class p_t {\n";
  //!>//+
  public class p_t {
  //-

    public static int main(String[] args) {

      //<? $O = "    ".(defined $Release ?
      //qq[System.out.println("Test version");] :
      //qq[System.out.println("Release version");]);
      //!>//+
      System.out.println("Release version");//-

      return 0;
    }
  }

In Makefile, add lines for updating p_t.java, and generating p.java
(readonly, so that you do not modify it accidentally):

  p.java: p_t.java
        starfish -o=$@ -e='$$Release=1' -mode=0400 $<
  tmp.ind: p_t.java
        starfish $<
        touch tmp.ind

=head2 Macros

Starfish includes a set of macro features (primitive, but in progress).
There are two modes, hidden macros and not hidden, which are indicated
using variable $Star->{HideMacros}, e.g.:

  starfish -e='$Star->{HideMacros}=1' *.sfish
  starfish *.sfish

Macros are activated with:

  <? $Star->defineMacros() !>

In Java mode, a macro can be defined in this way:

  //m!define macro name
  ...
  //m!end

After //m!end, a newline is mandatory.
After running Starfish, the definition will disapear in this place and
it will be appended as an auxdefine at the end of file.

In the following way, it can be defined and expanded in the same place:

  //m!defe macro name
  ...
  //m!end

A macro is expanded by:

  //m!expand macro name

When macro is expanded it looks like this:

  //m!expanded macro name
  ...
  //m!end

Macro is expanded even in hidden mode by:

  //m!fexpand macro name

and then it is expanded into:

  //m!fexpanded macro name
  ...
  //m!end

Hidden macros are put at the end of file in this way:

  //auxdefine macro name
  ...
  //endauxdefine

Old macro definition can be overriden by:

  //m!newdefe macro name
  ...
  //m!end

=head1 OPTIONS

=over 5

=item B<-o=>I<outputfile>

specifies an output file.  By default, the input file is used as the
output file.  If the specified output file is '-', then the output is
produced to the standard output.

=item B<-e=>I<initialcode>

specifies the initial Perl code to be executed.

=item B<-replace>

will cause the embedded code to be replaced with the output.
WARNING: Normally used only with B<-o>.

=item B<-mode=>I<mode>

specifies the mode for the output file.  By default, the mode of the
source file is used (the first one if more outputs are accumulated
using B<-o>).  If an output file is specified, and the mode is
specified, then C<starfish> will set temporarily the u+w mode of the
output file in order to write to that file, if needed.

=back

=head1 PREDEFINED VARIABLES

=over 5

=item C<$O>

After executing a snippet, the contents of this variable are inserted
into the file.

=item $Star

The Starfish object processing this file (this).

=item $Star->{INFILE}

Name of the current input file.

=back

=head1 METHODS

=head2 $o->addHook($p,$s,$f)

Adds a new hook. The parameter $p is the starting delimiter, $s is the
ending delimiter, and $f is the evaluator.
The parameters $p and $s can be either strings, which are matched
exactly, or regular expressions.  An empty ending delimiter will match
the end of the input.
There are several different ways of providing $f:

=over 5

=item special string 'default'

in which case the default Starfish evaluator is used,

=item special string 'ignore'

equivalent to producing no echo,

=item other strings

are interpreted as code which is embedded in an
    evaluator by providing a local $_, $self which is the current
    Starfish object, $p - the prefix, and $s the suffix.
    After executing the code $p.$_.$s is returned, unless in the
    replacement mode, in which $_ is returned.

=item code reference (sub {...})

is interpreted as code which is embedded in an evaluator.  The local 
$_ provides the captured string and it is to be replaced with the
result.  Three arguments are also provided to the code: $p - the
prefix, $_, and $s - the suffix.

=back

=head2 $o->last_update() 

Or just last_update(), returns the date of the last update of the
output.

=head2 $o->rmHook($p,$s)

Removes a hook specified by the starting delimiter $p, and the ending
delimiter $s.

=head2 $o->rmAllHooks()

Removes all hooks.  If no hooks are added, then after exiting the
current snippet it will not be possible to detect another snippet
later.  A typical usage could be as follows:

    $Star->rmAllHooks();
    $Star->addHook('<?starfish ','?>', 'default');

=head2 $o->setStyle($s)

Sets a particular style of the source file.  Currently implemented
options are: html, java, latex, makefile, perl, ps, python, TeX, and
tex.

=head1 PREDEFINED FUNCTIONS

=over 5

=item B<appendfile> I<filename>, I<list>

appends list elements to the file.

=item B<echo>

appends stuff to the special variable $O.

=item B<file_modification_time>

Returns modification time of this file (in format of Perl time).

=item B<file_modification_date>

Returns modification date of this file (in format: Month DD, YYYY).

=item B<getfile> I<file>

grabs the content of the file into a string or a list.

=item B<getmakefilelist> I<makefile>, I<var>

returns a list, which is a list of words assigned to the variable
I<var>; e.g.,

  FILE_LIST=file1 file2 file3\
    file4

  <? echo join "\n", getmakefilelist $Star->{INFILE}, 'FILE_LIST' !>

Embedded variables are not handled.

=item B<htmlquote> I<string>

The following definition is taken from the CIPP project
(F<http://aspn.activestate.com/ASPN/CodeDoc/CIPP/CIPP/Manual.html>):

This command quotes the content of a variable, so that it can be used
inside a HTML option or <TEXTAREA> block without the danger of syntax
clashes. The following conversions are done in this order:

       &  =>  &amp;
       <  =>  &lt;
       "  =>  &quot;

=item B<putfile> I<filename>, I<list>

opens file, writes the list elements to the file, and closes it.
`C<putfile> I<filename>' "touches" the file.

=item B<read_records> I<string>

The function takes one string argument.  If it starts with 'file='
then the rest of the string is treated as a file name, which contents
replaces the string in further processing.  The string is translated
into a list of records (hashes) and a reference to the list is
returned.  The records are separated by empty line, and in each line
an attribute and its value are separated by the first colon (:).
A line can be continued using backslash (\) at the end of line, or by
starting the next line with a space or tab.  Ending a line with \
effectively removes the "\\\n" string at the end of line, but 
"\n[ \t]" combination is replaced with "\n".
Comments, starting with the hash sign (#) are allowed between records.
An example is:

  id:1
  name: J. Public
  phone: 000-111

  id:2
  etc.

If an attribute is repeated, it will be renamed to an attribute of the
form att-1, att-2, etc.

=item B<read_starfish_conf>

Reads recursively (up the dir tree) configuration files C<starfish.conf>.

=back

=head1 LIMITATIONS AND BUGS

The script swallows the whole input file at once, so it may not work
on small-memory machines and with huge files.

=head1 THANKS

I'd like to thank Steve Yeago for comments.

=head1 AUTHOR

Copyright 2001-2006 Vlado Keselj www.cs.dal.ca/~vlado

This script is provided "as is" without expressed or implied warranty.
This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

The latest version can be found at F<http://www.cs.dal.ca/~vlado/srcperl/>.

=head1 SEE ALSO

There are several projects similar to Starfish.  Some of them are
text-embedded programming projects such as PHP with different
programming languages, and there are similar Perl-based projects.
When I was thinking about a need of a framework like this one (1998),
I have found ePerl project.  However, it was too heavy weight for my
purposes, and it did not support the "update" mode, vs. replace mode
of operation.  I learned about more projects over time and they are
included in the list below.

=over 4

=item [ePerl] ePerl

This script is somewhat similar to ePerl, about which you can read at
F<http://www.ossp.org/pkg/tool/eperl/>.  It was developed by Ralf
S. Engelshall in the period from 1996 to 1998.

=item Text::Template

Text::Template is a module with similar functionality as Starfish.
An interesting similarity is that the output variable in
Text::Template is called $OUT, compared to #O in Starfish.

=item php

F<http://www.php.net>

=item [ePerl-h] ePerl hack by David Ljung Madison

This is a Perl script simulating the ePerl functionality, but with
obviously much lower weight.  It is developed by David Ljung Madison,
and can be found at the URL: F<http://marginalhacks.com/Hacks/ePerl/>

=item [Text::Template] Perl module Text::Template by Mark Jason
  Dominus.

F<http://search.cpan.org/~mjd/Text-Template/>
Text::Template is a module with similar functionality as Starfish.
An interesting similarity is that the output variable in
Text::Template is called $OUT, compared to $O in Starfish.

=item [HTML::Mason] Perl module HTML::Mason by Jonathan Swartz, Dave
  Rolsky, and Ken Williams.

F<http://search.cpan.org/~drolsky/HTML-Mason-1.28/lib/HTML/Mason/Devel.pod>
The module HTML::Mason can also be seen as an embedded Perl system, but
it is a larger system with the design objective being a
"high-performance, dynamic web site authoring system".

=back

=cut
# $Id: Starfish.pm,v 3.43 2006/02/26 00:29:36 vlado Exp $
