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
    &testcase(22);

chdir '..' or die;

foreach my $i (15..21) {
    print `make test$i`;
}

chdir 'tmp' or die;

    &testcase(22);

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
	ok(getfile($procfile),
	   getfile("../testfiles/$outfile"));
    }
}

