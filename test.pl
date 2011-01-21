# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
#########################

use Test;
BEGIN { plan tests => 5 };
use Text::Starfish;
use File::Copy;
use Carp;
ok(1);				# made this far

# Slash hack was added because the Windows terminal evaluates does not
# evaluate $vars (the use a %varname% form instead) and therefore would
# not require the extra escape character at the beginning of the variable.
my $slash_hack;
if ($^O =~ m/MSWin/) {
	$slash_hack = '';
}
else {
	$slash_hack = '\\';
}
mkdir 'tmp', 0700 unless -d 'tmp';
mkdir 'tmp/Text', 0700 unless -d 'tmp/Text';
copy('Starfish.pm','tmp/Text/Starfish.pm');

{
    my $f = getfile('starfish');
    $f =~ s<^#!/usr/bin/perl>{#!/usr/bin/perl -I../blib/lib} or die;
    putfile('tmp/starfish', $f);
}

chdir 'tmp' or die;
&testcase('01', 'replace');
&testcase('02', 'replace');
&testcase('03', 'replace');
&testcase('05', 'replace');
&testcase('06'); # was 5
&testcase('07'); # was 25, Makefile
&testcase('08'); # Makefile
&testcase('09', 'replace'); # old 7, html
&testcase(2);
&testcase(3);
&testcase(4);
&testcase(6, 'out');
&testcase(8);
&testcase(9, 'out');
# 10
    copy('../testfiles/9_java.out', '9_java.out');
    #`perl -I. -- starfish -o=10_java.out -e="$slash_hack\$Starfish::HideMacros=1" 9_java.out`;
    starfish_cmd(qw(-o=10_java.out -e=$Starfish::HideMacros=1 9_java.out));
    ok(getfile('10_java.out'),
	   getfile("../testfiles/10_java.out"));
    # 11
    copy('../testfiles/10_java.out', '10.java');
    #`perl -I. -- starfish -o=11_java.out 10.java`;
    starfish_cmd(qw(-o=11_java.out 10.java));
    ok(getfile('11_java.out'),
	   getfile("../testfiles/11_java.out"));
    # 12
	`echo "OSNAME | $OSNAME |"`;
	# Skip if it is windows
	if ($^O =~ m/MSWin/) {
		skip('Skipped under windows...');
	}
	else {
		copy('../testfiles/10_java.out', '12.java');
		#`perl -I. -- starfish -o=12.out -mode=0444 12.java`;
		starfish_cmd(qw(-o=12.out -mode=0444 12.java));
		my $tmp = `ls -l 12.out|sed 's/ .*//'`;
		`chmod u+r+w 12.out`;
		ok($tmp, getfile("../testfiles/12.out"));
    }

    &testcase(13, 'out');

    # 14
    copy('../testfiles/13_java.in','14.java');
    #`perl -I. -- starfish -o=14.out -e="$slash_hack\$Star::HideMacros=1" 14.java`;
    starfish_cmd(qw(-o=14.out -e=$Star::HideMacros=1 14.java));
    ok(getfile('14.out'),
       getfile('../testfiles/14.out'));

    # 15,16
    copy('../testfiles/15.java','tmp.java');
    `$^X -I. -- starfish -o=tmp.ERR -e="$slash_hack\$Star::HideMacros=1" tmp.java>tmp1 2>&1`;
    ok($? != 0);
    okfiles('../testfiles/15.out', 'tmp1');

    # 17, old 16
    copy('../testfiles/16develop.SLeP','tmp.SLeP');
    copy('../testfiles/16.tex','tmp.tex');
    `$^X -I. -- starfish tmp.SLeP tmp.tex`;
	if ($^O =~ m/MSWin/) {
	    `copy /B /Y tmp.SLeP+tmp.tex tmp1`;
	}
	else {
	    `cat tmp.SLeP tmp.tex>tmp1`;
	}
    okfiles('../testfiles/16.out', 'tmp1');

    # 18, old 17
    copy('../testfiles/p_t.java','tmp.java');
    `$^X -I. -- starfish -o=tmp1 tmp.java`;
    okfiles('../testfiles/17.out', 'tmp1');

    # 19, old 18
    copy('../testfiles/p_t.java', 'tmp.java');
    `$^X -I. -- starfish -e="$slash_hack\$Release=1" -o=tmp1 tmp.java`;
    okfiles('../testfiles/18.out', 'tmp1');

    # 20, old 19
	if ($^O =~ m/MSWin/) {
		skip('Skipped under windows...');
	}
	else {
		copy('../testfiles/19.html', 'tmp.html');
	    `$^X -I. -- starfish -replace -o=tmp2 -mode=0644 tmp.html`;
	    `ls -l tmp2|sed 's/ .*//'>tmp1`;
		okfiles('../testfiles/19.out', 'tmp1');
	}

    # 21, old 20 has to be done after previous
	if ($^O =~ m/MSWin/) {
		skip('Skipped under windows...');
	}
	else {
	    `$^X -I. -- starfish -replace -o=tmp2 tmp.html`;
	    `ls -l tmp2|sed 's/ .*//'>tmp1`;
	    okfiles('../testfiles/20.out', 'tmp1');
	}

    # 22, old 21
    copy('../testfiles/21.html','tmp2.html');
    `$^X -I. -- starfish -replace -o=tmp1 tmp2.html`;
    okfiles('../testfiles/21.out', 'tmp1');

    # 23
    &testcase(22);    

    # 24
    copy('../testfiles/24.py','24.py');
    `$^X -I. -- starfish 24.py`;
    okfiles('../testfiles/24.py.out', '24.py');

    # 26
    copy('../testfiles/26_include_example.html','26_include_example.html');
    copy('../testfiles/26_include_example1.html','26_include_example1.html');
    starfish_cmd(qw(-replace -o=26-out.html 26_include_example.html));
    okfiles('../testfiles/26-out.html', '26-out.html');

sub okfiles {
    my $f1 = shift;
    while (@_) {
	my $f2 = shift;
	if (! ok(getfile($f2), getfile($f1)) )
	{ print STDERR "pwd=".`pwd`."Files: $f1 and $f2\n" }

    }
}

sub getfile($) {
    my $f = shift;
    local *F;
    open(F, "<$f") or croak "getfile:cannot open $f:$!";
    my @r = <F>;
    close(F);
    return wantarray ? @r : join ('', @r);
}

sub testcase {
    my $testnum = shift;
    my ($infile, $procfile, $replace, $out, $outfile);

    if ( -e "../testfiles/$testnum.in" and $#_==-1) {
	$infile   = "$testnum.in";
	$procfile = "$testnum.in";
	$outfile  = "$testnum.out";
    }
    elsif ( -e "../testfiles/$testnum.in" and
	    $#_==0 and $_[0] eq 'out' ) {
	$infile   = "$testnum.in";
	$procfile = "$testnum.in";
	$outfile  = "$testnum.out";
	$out      = "$testnum.out";
    }
    elsif ( -e "../testfiles/$testnum.in" and
	    $#_==0 and $_[0] eq 'replace' ) {
	$infile   = "$testnum.in";
	$procfile = "$testnum.in";
	$outfile  = "$testnum.out";
	$replace  = "$testnum.out";
    }
    elsif ( -e "../testfiles/${testnum}_html.in" ) {
	$infile = "${testnum}_html.in";
	$procfile = "$testnum.html";
	$outfile = "${testnum}_html.out";
        if ($#_ > -1 and $_[0] eq 'replace')
	{  $replace = "${testnum}_out.html" }
    }
    elsif ( -e "../testfiles/${testnum}_Makefile.in" ) {
	$infile = "${testnum}_Makefile.in";
	$procfile = "Makefile";
	$outfile = "${testnum}_Makefile.out";
        if ($#_ > -1 and $_[0] eq 'replace')
	{  $replace = "${testnum}_Makefile.out" }
    }
    elsif ( -e "../testfiles/${testnum}_tex.in" ) {
	my $ext = $1;
	$infile = "${testnum}_tex.in";
	$procfile = "$testnum.tex";
	$outfile = "${testnum}_tex.out";
        if ($#_ > -1 and $_[0] eq 'replace')
	{  $replace = "${testnum}_out.tex" }
    }
    elsif ( -e "../testfiles/${testnum}.html.sfish" ) {
	$infile = "${testnum}.html.sfish";
	$procfile = "$testnum.html.sfish";
	$replace = "$testnum.html";
	$outfile = "${testnum}_html.out";
    }
    elsif ( -e "../testfiles/${testnum}_java.in" and
	    $#_==0 and $_[0] eq 'out' ) {
	$infile = "${testnum}_java.in";
	$procfile = "$testnum.java";
	$outfile = "${testnum}_java.out";
	$out     = "${testnum}_java.out";
    }
    else { die }

    copy("../testfiles/$infile", "$procfile");
    if ($replace) {
	#`perl -I. -- starfish -e="$slash_hack\$ver=\"testver\"" -replace -o=$replace $procfile`;
	starfish_cmd('-e=$ver="testver"', '-replace', "-o=$replace", $procfile);
	okfiles("../testfiles/$outfile", $replace);
    }
    elsif ($out) {
	#`perl -I. -- starfish -e="$slash_hack\$ver=\"testver\"" -o=$out $procfile`;
	starfish_cmd('-e=$ver="testver"', "-o=$out", $procfile);
	okfiles("../testfiles/$outfile", $out);
    }
    else {
	#`perl -I. -- starfish -e="$slash_hack\$ver=\"testver\"" $procfile`;
	starfish_cmd('-e=$ver="testver"', $procfile);
	okfiles("../testfiles/$outfile", $procfile);
    }
}
