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
mkdir 'Text', 0700 unless -d 'Text';
`ln -s ../Starfish.pm Text/Starfish.pm`;

foreach my $i (1..21) {
    print `make test$i`;
}
