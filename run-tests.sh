#!/bin/sh
#
# Test suite for abuild(1), newapkbuild(1), and friends
# 
# Copyright (c) 2018, A. Wilcox <awilfox@adelielinux.org>
# Licensed under the GPL 2.0 only.  No later version.
#

#####################################################################
# Ground rules:
# 
# * Must be POSIX shell compatible (no bash / dash extensions)
# * Must test all common operations of newapkbuild
#   (not necessarily every single kind of package, but common ones)
# * Must test all operations of abuild
#####################################################################


####################
# SOME HELPFUL FNS #
####################

# Note: We always use colours.
NORMAL="\033[1;0m"
STRONG="\033[1;1m"
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"

GOOD_TESTS=0
SKIP_TESTS=0
FAIL_TESTS=0


##
# I've used green for OK, yellow for skipped tests, and red for failed tests.
# I also made sure each one jets out from the other, in case an operator may
# be colour-blind.  Please don't change the text to align (GOOD/SKIP/FAIL),
# as this is meant to be as easy to read for as many people as possible.
##

# $1 = test name
# prints "OK: Test name" then increments GOOD_TESTS
good() {
	printf "${GREEN}OK${NORMAL}: $1\n"
	GOOD_TESTS=$((GOOD_TESTS+1))
}

# $1 = test name
# prints "SKIP: Test name" then increments SKIP_TESTS
skip() {
	printf "${YELLOW}SKIP${NORMAL}: $1\n"
	SKIP_TESTS=$((SKIP_TESTS+1))
}

# $1 = test name
# prints "FAILED: Test name" then increments FAIL_TESTS
fail() {
	printf "${RED}FAILED${NORMAL}: $1\n"
	FAIL_TESTS=$((FAIL_TESTS+1))
	[ -n "${DEBUG}" ] && exit 1
}


expect_success() {
	if [ $? -eq 0 ]; then
		good $1
	else
		fail $1
	fi
}

expect_success_with_file() {
	if [ $? -eq 0 ]; then
		if [ -f $2 ]; then
			good $1
		else
			fail "$1 - expected file $2 was not present"
		fi
	else
		fail $1
	fi
}

expect_failure() {
	if [ $? -eq 0 ]; then
		fail $1
	else
		good $1
	fi
}



####################
# TESTS: abuild(1) #
####################

# params:
# $1 - test name (tests/$FOO/APKBUILD)
# $2 - phase to test (verify, etc)
# $3 - expect_success, expect_success_with_file, or expect_failure
# $4 - optional second parameter to your expect_* function if it needs one
abuild_test() {
	local file
	file=tests/abuild/$1/APKBUILD

	if ! [ -f $file ]; then
		skip $1
	else
		APKBUILD=$file ./abuild $2 1>last-test-out.log 2>last-test-err.log
		$3 $1 $4
	fi
}


# Does the system verify checksums correctly?
abuild_test verify1 verify expect_success
abuild_test verify2 verify expect_failure

# Does the system run test suites properly?
abuild_test check1 check expect_success_with_file "tests/abuild/check1/src/checked"
abuild_test check2 check expect_failure
abuild_test checkroot1 check expect_success



#########################
# TESTS: newapkbuild(1) #
#########################

# params:
# $1 - test name
# $2 - pattern to grep for in created APKBUILD
# all other params - passed to newapkbuild
newapkbuild_simple_test() {
	set $@
	local name pattern
	name=$1
	shift
	pattern=$1
	shift
	pushd "tests/newapkbuild" 1>/dev/null
	[ -d $name ] && rm -r $name
	newapkbuild -n $name $@
	if [ $? -ne 0 ]; then
		fail $name
		return
	fi
	grep $pattern $name/APKBUILD 1>/dev/null
	expect_success $name
	popd 1>/dev/null
}


newapkbuild_simple_test simplename 'pkgname=simplename' simplename-1.0
newapkbuild_simple_test simpledesc 'pkgdesc="Example"' -d "Example" simpledesc-1.0
newapkbuild_simple_test simplever  'pkgver=1.0' simplever-1.0


# params:
# $1 - test name (test-autoconf-pkg, etc)
# $2 - the invocation expected ("./configure", "cmake", etc)
newapkbuild_pkg_test() {
	pushd "tests/newapkbuild" 1>/dev/null
	[ -d $1 ] && rm -r $1
	newapkbuild "https://distfiles.adelielinux.org/source/newapkbuild-tests/$1-1.0.tar.xz" 1>/dev/null 2>/dev/null
	popd 1>/dev/null
	if [ $? -ne 0 ]; then
		fail "$1: newapkbuild failed"
	else
		grep "$2"         tests/newapkbuild/$1/APKBUILD 1>/dev/null
		if [ $? -ne 0 ]; then fail "$1: no '$2' invocation found"; return 1; fi
		grep "pkgname=$1" tests/newapkbuild/$1/APKBUILD 1>/dev/null
		if [ $? -ne 0 ]; then fail "$1: wrong name"; return 1; fi
		grep 'pkgver=1.0' tests/newapkbuild/$1/APKBUILD 1>/dev/null
		if [ $? -ne 0 ]; then fail "$1: wrong version"; return 1; fi
		expect_success $1
	fi
}


newapkbuild_pkg_test test-autoconf-pkg "./configure"
newapkbuild_pkg_test test-cmake-pkg "cmake"
newapkbuild_pkg_test test-pkg "make"


##########
# FINISH #
##########

printf "\n\n== Test Summary ==\n"

if [ ${GOOD_TESTS} -gt 0 ]; then
	good "${GOOD_TESTS} test(s)"
fi


if [ ${SKIP_TESTS} -gt 0 ]; then
	skip "${SKIP_TESTS} test(s)"
fi


if [ ${FAIL_TESTS} -gt 0 ]; then
	fail "${FAIL_TESTS} test(s)"
fi

printf "\n"


if [ -z "${DEBUG}" ]; then
	rm last-test-out.log
	rm last-test-err.log
fi

# fini
