# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 1 };
use Text::Starfish;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

mkdir 'tmp', 0700 unless -d 'tmp';
mkdir 'tmp/Text', 0700 unless -d 'tmp/Text';
`ln -s ../../Starfish.pm tmp/Text/Starfish.pm`
    unless -l 'tmp/Text/Starfish.pm';
`ln -s ../starfish tmp/starfish` unless -l 'tmp/starfish';
chdir 'tmp' or die;

&testcase(1);


chdir '..' or die;

foreach my $i (2..21) {
    print `make test$i`;
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

    `cp ../testfiles/$testnum.in .`;
    `./starfish $testnum.in`;
    ok(getfile("$testnum.in"),
       getfile("../testfiles/$testnum.out"));
}

