use ExtUtils::MakeMaker;

# $Id: Makefile.PL,v 3.2 2002/12/12 16:46:45 vlado Exp $

WriteMakefile(
    'NAME'		=> 'Text::Starfish',
    'ABSTRACT'          => 'Yet another embedded Perl',
    'VERSION_FROM'	=> 'Starfish.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
       (
      #ABSTRACT_FROM => 'Starfish.pm', # retrieve abstract from module
       AUTHOR     => 'Vlado Keselj www.cs.dal.ca/~vlado') : ()),
    'dist'  => {'COMPRESS'=>'gzip', 'SUFFIX' => 'gz'}
    ,'clean' => {FILES => "tmp* Text"}
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

test1:;@echo -n $@:&&cp testfiles/1.in tmp1 && ${TEST_PROG}  tmp1&&$(DIFF) testfiles/1.out&&echo -n 'OK '
testv1:
	@echo -n $@:
	cp testfiles/1.in tmp1 && ${TEST_PROG}  tmp1&&$(DIFF) testfiles/1.out
TEST_LIST+= test1
TESTV_LIST+= testv1
mktest1:
	@echo -n $@:
	cp testfiles/1.in tmp1&&${TEST_PROG}  tmp1&& cp tmp1 testfiles/1.out
MKTEST_LIST+= mktest1

test2:;@echo -n $@:&&cp testfiles/2.in tmp1 && ${TEST_PROG} -e='$$ver="testver"' tmp1&&$(DIFF) testfiles/2.out&&echo -n 'OK '
testv2:
	@echo -n $@:
	cp testfiles/2.in tmp1 && ${TEST_PROG} -e='$$ver="testver"' tmp1&&$(DIFF) testfiles/2.out
TEST_LIST+= test2
TESTV_LIST+= testv2
mktest2:
	@echo -n $@:
	cp testfiles/2.in tmp1&&${TEST_PROG} -e='$$ver="testver"' tmp1&& cp tmp1 testfiles/2.out
MKTEST_LIST+= mktest2

test3:;@echo -n $@:&&cp testfiles/2.out tmp1 && ${TEST_PROG} -e='$$ver="testver"' tmp1&&$(DIFF) testfiles/2.out&&echo -n 'OK '
testv3:
	@echo -n $@:
	cp testfiles/2.out tmp1 && ${TEST_PROG} -e='$$ver="testver"' tmp1&&$(DIFF) testfiles/2.out
TEST_LIST+= test3
TESTV_LIST+= testv3

test4:;@echo -n $@:&&cp testfiles/4.in tmp1 && ${TEST_PROG}  tmp1&&$(DIFF) testfiles/4.out&&echo -n 'OK '
testv4:
	@echo -n $@:
	cp testfiles/4.in tmp1 && ${TEST_PROG}  tmp1&&$(DIFF) testfiles/4.out
TEST_LIST+= test4
TESTV_LIST+= testv4
mktest4:
	@echo -n $@:
	cp testfiles/4.in tmp1&&${TEST_PROG}  tmp1&& cp tmp1 testfiles/4.out
MKTEST_LIST+= mktest4

test5:;@echo -n $@:&&cp testfiles/5.in tmp1 && ${TEST_PROG}  tmp1&&$(DIFF) testfiles/5.out&&echo -n 'OK '
testv5:
	@echo -n $@:
	cp testfiles/5.in tmp1 && ${TEST_PROG}  tmp1&&$(DIFF) testfiles/5.out
TEST_LIST+= test5
TESTV_LIST+= testv5
mktest5:
	@echo -n $@:
	cp testfiles/5.in tmp1&&${TEST_PROG}  tmp1&& cp tmp1 testfiles/5.out
MKTEST_LIST+= mktest5

test6:;@echo -n $@:&&cp testfiles/5.in tmp2&&${TEST_PROG} -o=tmp1 tmp2&&$(DIFF) testfiles/5.out&&echo -n 'OK '
testv6:
	@echo -n $@:
	cp testfiles/5.in tmp2&&${TEST_PROG} -o=tmp1 tmp2&&$(DIFF) testfiles/5.out
TEST_LIST+= test6
TESTV_LIST+= testv6

test7:;@echo -n $@:&&cp testfiles/7.html tmp2.html&&${TEST_PROG} -replace -o=tmp1 tmp2.html&&$(DIFF) testfiles/7.out&&echo -n 'OK '
testv7:
	@echo -n $@:
	cp testfiles/7.html tmp2.html&&${TEST_PROG} -replace -o=tmp1 tmp2.html&&$(DIFF) testfiles/7.out
TEST_LIST+= test7
TESTV_LIST+= testv7
mktest7:
	@echo -n $@:
	cp testfiles/7.html tmp2.html&&${TEST_PROG} -replace -o=tmp1 tmp2.html&& cp tmp1 testfiles/7.out
MKTEST_LIST+= mktest7

test8:;@echo -n $@:&&cp testfiles/8.in tmp1 && ${TEST_PROG}  tmp1&&$(DIFF) testfiles/8.out&&echo -n 'OK '
testv8:
	@echo -n $@:
	cp testfiles/8.in tmp1 && ${TEST_PROG}  tmp1&&$(DIFF) testfiles/8.out
TEST_LIST+= test8
TESTV_LIST+= testv8
mktest8:
	@echo -n $@:
	cp testfiles/8.in tmp1&&${TEST_PROG}  tmp1&& cp tmp1 testfiles/8.out
MKTEST_LIST+= mktest8
TEST_LIST+= newLine

test9:;@echo -n $@:&&cp  testfiles/9.java tmp.java&&${TEST_PROG} -o=tmp1 tmp.java&&$(DIFF) testfiles/9.out&&echo -n 'OK '
testv9:
	@echo -n $@:
	cp  testfiles/9.java tmp.java&&${TEST_PROG} -o=tmp1 tmp.java&&$(DIFF) testfiles/9.out
TEST_LIST+= test9
TESTV_LIST+= testv9
mktest9:
	@echo -n $@:
	cp  testfiles/9.java tmp.java&&${TEST_PROG} -o=tmp1 tmp.java&& cp tmp1 testfiles/9.out
MKTEST_LIST+= mktest9

test10:;@echo -n $@:&&cp testfiles/9.out tmp.java&&${TEST_PROG} -o=tmp1 -e='$$Starfish::HideMacros=1' tmp.java&&$(DIFF) testfiles/10.out&&echo -n 'OK '
testv10:
	@echo -n $@:
	cp testfiles/9.out tmp.java&&${TEST_PROG} -o=tmp1 -e='$$Starfish::HideMacros=1' tmp.java&&$(DIFF) testfiles/10.out
TEST_LIST+= test10
TESTV_LIST+= testv10
mktest10:
	@echo -n $@:
	cp testfiles/9.out tmp.java&&${TEST_PROG} -o=tmp1 -e='$$Starfish::HideMacros=1' tmp.java&& cp tmp1 testfiles/10.out
MKTEST_LIST+= mktest10

test11:;@echo -n $@:&&cp testfiles/10.out tmp.java&&${TEST_PROG} -o=tmp1 tmp.java&&$(DIFF) testfiles/11.out&&echo -n 'OK '
testv11:
	@echo -n $@:
	cp testfiles/10.out tmp.java&&${TEST_PROG} -o=tmp1 tmp.java&&$(DIFF) testfiles/11.out
TEST_LIST+= test11
TESTV_LIST+= testv11
mktest11:
	@echo -n $@:
	cp testfiles/10.out tmp.java&&${TEST_PROG} -o=tmp1 tmp.java&& cp tmp1 testfiles/11.out
MKTEST_LIST+= mktest11

test12:;@echo -n $@:&&cp testfiles/10.out tmp.java&&${TEST_PROG} -o=tmp2 -mode=0444 tmp.java&&ls -l tmp2|sed 's/ .*//'>tmp1&&chmod u+r+w tmp2&&$(DIFF) testfiles/12.out&&echo -n 'OK '
testv12:
	@echo -n $@:
	cp testfiles/10.out tmp.java&&${TEST_PROG} -o=tmp2 -mode=0444 tmp.java&&ls -l tmp2|sed 's/ .*//'>tmp1&&chmod u+r+w tmp2&&$(DIFF) testfiles/12.out
TEST_LIST+= test12
TESTV_LIST+= testv12
mktest12:
	@echo -n $@:
	cp testfiles/10.out tmp.java&&${TEST_PROG} -o=tmp2 -mode=0444 tmp.java&&ls -l tmp2|sed 's/ .*//'>tmp1&&chmod u+r+w tmp2&& cp tmp1 testfiles/12.out
MKTEST_LIST+= mktest12

test13:;@echo -n $@:&&cp testfiles/13.java tmp.java&&${TEST_PROG} -o=tmp1 tmp.java&&$(DIFF) testfiles/13.out&&echo -n 'OK '
testv13:
	@echo -n $@:
	cp testfiles/13.java tmp.java&&${TEST_PROG} -o=tmp1 tmp.java&&$(DIFF) testfiles/13.out
TEST_LIST+= test13
TESTV_LIST+= testv13
mktest13:
	@echo -n $@:
	cp testfiles/13.java tmp.java&&${TEST_PROG} -o=tmp1 tmp.java&& cp tmp1 testfiles/13.out
MKTEST_LIST+= mktest13

test14:;@echo -n $@:&&cp testfiles/13.java tmp.java&&${TEST_PROG} -o=tmp1 -e='$$Starfish::HideMacros=1' tmp.java&&$(DIFF) testfiles/14.out&&echo -n 'OK '
testv14:
	@echo -n $@:
	cp testfiles/13.java tmp.java&&${TEST_PROG} -o=tmp1 -e='$$Starfish::HideMacros=1' tmp.java&&$(DIFF) testfiles/14.out
TEST_LIST+= test14
TESTV_LIST+= testv14
mktest14:
	@echo -n $@:
	cp testfiles/13.java tmp.java&&${TEST_PROG} -o=tmp1 -e='$$Starfish::HideMacros=1' tmp.java&& cp tmp1 testfiles/14.out
MKTEST_LIST+= mktest14

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
