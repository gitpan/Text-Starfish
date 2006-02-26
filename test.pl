# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
#########################

use Test;
BEGIN { plan tests => 5 };
use Text::Starfish;
ok(1);				# made this far

mkdir 'tmp', 0700 unless -d 'tmp';
mkdir 'tmp/Text', 0700 unless -d 'tmp/Text';
`ln -s ../../Starfish.pm tmp/Text/Starfish.pm`
    unless -l 'tmp/Text/Starfish.pm';

{
    my $f = getfile('starfish');
    $f =~ s{^#!/usr/bin/perl -s}{#!/usr/bin/perl -s -I../blib/lib} or die;
    putfile('tmp/starfish', $f);
    `chmod u+x tmp/starfish`;
}

chdir 'tmp' or die;

    &testcase(2);
    &testcase(3);
    &testcase(4);
    &testcase(5);
    &testcase(6, 'out');
    &testcase(7, 'replace');
    &testcase(8);
    &testcase(9, 'out');
    # 10
    `cp ../testfiles/9_java.out .`;
    `./starfish -o=10_java.out -e='\$Starfish::HideMacros=1' 9_java.out`;
    ok(getfile('10_java.out'),
	   getfile("../testfiles/10_java.out"));
    # 11
    `cp ../testfiles/10_java.out 10.java`;
    `./starfish -o=11_java.out 10.java`;
    ok(getfile('11_java.out'),
	   getfile("../testfiles/11_java.out"));
    # 12
    `cp ../testfiles/10_java.out 12.java`;
    `./starfish -o=12.out -mode=0444 12.java`;
    my $tmp = `ls -l 12.out|sed 's/ .*//'`;
    `chmod u+r+w 12.out`;
    ok($tmp, getfile("../testfiles/12.out"));
    
    &testcase(13, 'out');

    # 14
    `cp ../testfiles/13_java.in 14.java`;
    `./starfish -o=14.out -e='\$Star::HideMacros=1' 14.java`;
    ok(getfile('14.out'),
       getfile('../testfiles/14.out'));

    # 15,16
    `cp ../testfiles/15.java tmp.java`;
    `./starfish -o=tmp.ERR -e'\$Star::HideMacros=1' tmp.java>tmp1 2>&1`;
    ok($? != 0);
    okfiles('../testfiles/15.out', 'tmp1');

    # 17, old 16
    `cp ../testfiles/16develop.SLeP tmp.SLeP`;
    `cp ../testfiles/16.tex tmp.tex`;
    `./starfish tmp.SLeP tmp.tex`;
    `cat tmp.SLeP tmp.tex>tmp1`;
    okfiles('../testfiles/16.out', 'tmp1');

    # 18, old 17
    `cp ../testfiles/p_t.java tmp.java`;
    `./starfish -o=tmp1 tmp.java`;
    okfiles('../testfiles/17.out', 'tmp1');

    # 19, old 18
    `cp ../testfiles/p_t.java tmp.java`;
    `./starfish -e='\$Release=1' -o=tmp1 tmp.java`;
    okfiles('../testfiles/18.out', 'tmp1');

    # 20, old 19
    `cp ../testfiles/19.html tmp.html`;
    `./starfish -replace -o=tmp2 -mode=0644 tmp.html`;
    `ls -l tmp2|sed 's/ .*//'>tmp1`;
    okfiles('../testfiles/19.out', 'tmp1');

    # 21, old 20 has to be done after previous
    `./starfish -replace -o=tmp2 tmp.html`;
    `ls -l tmp2|sed 's/ .*//'>tmp1`;
    okfiles('../testfiles/20.out', 'tmp1');

    # 22, old 21
    `cp ../testfiles/21.html tmp2.html`;
    `./starfish -replace -o=tmp1 tmp2.html`;
    okfiles('../testfiles/21.out', 'tmp1');

    # 23
    &testcase(22);    

    # 24
    `cp ../testfiles/24.py 24.py`;
    `./starfish 24.py`;
    okfiles('../testfiles/24.py.out', '24.py');

sub okfiles {
    my $f1 = shift;
    while (@_) {
	my $f2 = shift;
	ok(getfile($f1), getfile($f2));
    }
}

sub getfile($) {
    my $f = shift;
    local *F;
    open(F, "<$f") or die "getfile:cannot open $f:$!";
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
    elsif ( -e "../testfiles/${testnum}_html.in" ) {
	$infile = "${testnum}_html.in";
	$procfile = "$testnum.html";
	$outfile = "${testnum}_html.out";
        if ($#_ > -1 and $_[0] eq 'replace')
	{  $replace = "${testnum}_out.html" }
    }
    elsif ( -e "../testfiles/${testnum}_java.in" and
	    $#_==0 and $_[0] eq 'out' ) {
	$infile = "${testnum}_java.in";
	$procfile = "$testnum.java";
	$outfile = "${testnum}_java.out";
	$out     = "${testnum}_java.out";
    }
    else { die }

    #print "cp ../testfiles/$infile $procfile\n";
    `cp ../testfiles/$infile $procfile`;
    if ($replace) {
	`./starfish -e='\$ver="testver"' -replace -o=$replace $procfile`;
	ok(getfile($replace),
	   getfile("../testfiles/$outfile"));
    }
    elsif ($out) {
	`./starfish -e='\$ver="testver"' -o=$out $procfile`;
	ok(getfile($out),
	   getfile("../testfiles/$outfile"));
    }
    else {
	#print "./starfish -e='\$ver=\"testver\"' $procfile\n";
	`./starfish -e='\$ver="testver"' $procfile`;
	ok(getfile($procfile), getfile("../testfiles/$outfile"));
    }
}
