use ExtUtils::MakeMaker;

# $Id: Makefile.PL,v 3.10 2003/08/13 12:10:04 vlado Exp $

WriteMakefile(
    'NAME'		=> 'Text::Starfish',
    'ABSTRACT'          => 'Yet another embedded Perl',
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

# dirty addition... (I need to learn more about MakeMaker I
# suppose...)

open(M, ">>Makefile") or die;
print M "mktest:";
foreach my $i (1..21) { print M " mktest$i" }
print M "\ntestall:";
foreach my $i (1..21) { print M " test$i" }
print M "\n\n";

print M q~
TEST_PROG=./starfish
DIFF=diff tmp1
DIFF1=diff tmp/tmp1

test15:;@echo -n $@:&&cp testfiles/15.java tmp.java&&(${TEST_PROG} -o=tmp.ERR -e='$$Starfish::HideMacros=1' tmp.java>tmp1 2>&1)||echo ok>>tmp1&&$(DIFF) testfiles/15.out&&echo -n 'OK '
testv15:
	@echo -n $@:
	cp testfiles/15.java tmp.java&&(${TEST_PROG} -o=tmp.ERR -e='$$Starfish::HideMacros=1' tmp.java>tmp1 2>&1)||echo ok>>tmp1&&$(DIFF) testfiles/15.out
TEST_LIST+= test15
TESTV_LIST+= testv15
mktest15:
	@echo -n $@:
	cp testfiles/15.java tmp.java&&(${TEST_PROG} -o=tmp.ERR -e='$$Starfish::HideMacros=1' tmp.java>tmp1 2>&1)||echo ok>>tmp1&& cp tmp1 testfiles/15.out
MKTEST_LIST+= mktest15

test16:;@echo -n $@:&&cp testfiles/16develop.SLeP tmp.SLeP && cp testfiles/16.tex tmp.tex&&${TEST_PROG} tmp.SLeP tmp.tex&& cat tmp.SLeP tmp.tex>tmp1&&$(DIFF) testfiles/16.out&&echo -n 'OK '
testv16:
	@echo -n $@:
	cp testfiles/16develop.SLeP tmp.SLeP && cp t/16.tex tmp.tex&&${TEST_PROG} tmp.SLeP tmp.tex&& cat tmp.SLeP tmp.tex>tmp1&&$(DIFF) testfiles/16.out
TEST_LIST+= test16
TESTV_LIST+= testv16
mktest16:
	@echo -n $@:
	cp testfiles/16develop.SLeP tmp.SLeP && cp t/16.tex tmp.tex&&${TEST_PROG} tmp.SLeP tmp.tex&& cat tmp.SLeP tmp.tex>tmp1&& cp tmp1 testfiles/16.out
MKTEST_LIST+= mktest16

test17:;@echo -n $@:&&cp testfiles/p_t.java tmp.java && ${TEST_PROG} -o=tmp1 tmp.java&&$(DIFF) testfiles/17.out&&echo -n 'OK '
testv17:
	@echo -n $@:
	cp testfiles/p_t.java tmp.java && ${TEST_PROG} -o=tmp1 tmp.java&&$(DIFF) testfiles/17.out
TEST_LIST+= test17
TESTV_LIST+= testv17
mktest17:
	@echo -n $@:
	cp testfiles/p_t.java tmp.java && ${TEST_PROG} -o=tmp1 tmp.java&& cp tmp1 testfiles/17.out
MKTEST_LIST+= mktest17

test18:;@echo -n $@:&&cp testfiles/p_t.java tmp.java && ${TEST_PROG} -e='$$Release=1' -o=tmp1 tmp.java&&$(DIFF) testfiles/18.out&&echo -n 'OK '
testv18:
	@echo -n $@:
	cp testfiles/p_t.java tmp.java && ${TEST_PROG} -e='$$Release=1' -o=tmp1 tmp.java&&$(DIFF) testfiles/18.out
TEST_LIST+= test18
TESTV_LIST+= testv18
mktest18:
	@echo -n $@:
	cp testfiles/p_t.java tmp.java && ${TEST_PROG} -e='$$Release=1' -o=tmp1 tmp.java&& cp tmp1 testfiles/18.out
MKTEST_LIST+= mktest18

test19:;@echo -n $@:&&cp testfiles/19.html tmp/tmp.html && ${TEST_PROG} -replace -o=tmp/tmp2 -mode=0644 tmp/tmp.html&& ls -l tmp/tmp2|sed 's/ .*//'>tmp1&&$(DIFF) testfiles/19.out&&echo -n 'OK '
testv19:
	@echo -n $@:
	cp testfiles/19.html tmp/tmp.html && ${TEST_PROG} -replace -o=tmp/tmp2 -mode=0644 tmp/tmp.html&& ls -l tmp/tmp2|sed 's/ .*//'>tmp1&&$(DIFF) testfiles/19.out
TEST_LIST+= test19
TESTV_LIST+= testv19
mktest19:
	@echo -n $@:
	cp testfiles/19.html tmp/tmp.html && ${TEST_PROG} -replace -o=tmp/tmp2 -mode=0644 tmp/tmp.html&& ls -l tmp/tmp2|sed 's/ .*//'>tmp1&& cp tmp1 testfiles/19.out
MKTEST_LIST+= mktest19
# 20 has to be done after 19

test20:;@echo -n $@:&&${TEST_PROG} -replace -o=tmp/tmp2 tmp/tmp.html&& ls -l tmp/tmp2|sed 's/ .*//'>tmp1&&$(DIFF) testfiles/20.out&&echo -n 'OK '
testv20:
	@echo -n $@:
	${TEST_PROG} -replace -o=tmp/tmp2 tmp/tmp.html&& ls -l tmp/tmp2|sed 's/ .*//'>tmp1&&$(DIFF) testfiles/20.out
TEST_LIST+= test20
TESTV_LIST+= testv20
mktest20:
	@echo -n $@:
	${TEST_PROG} -replace -o=tmp/tmp2 tmp/tmp.html&& ls -l tmp/tmp2|sed 's/ .*//'>tmp1&& cp tmp1 testfiles/20.out
MKTEST_LIST+= mktest20

test21:;@echo -n $@:&&cp testfiles/21.html tmp2.html&&${TEST_PROG} -replace -o=tmp1 tmp2.html&&$(DIFF) testfiles/21.out&&echo -n 'OK '
testv21:
	@echo -n $@:
	cp testfiles/21.html tmp2.html&&${TEST_PROG} -replace -o=tmp1 tmp2.html&&$(DIFF) testfiles/21.out
TEST_LIST+= test21
TESTV_LIST+= testv21
mktest21:
	@echo -n $@:
	cp testfiles/21.html tmp2.html&&${TEST_PROG} -replace -o=tmp1 tmp2.html&& cp tmp1 testfiles/21.out
MKTEST_LIST+= mktest21

~;

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
