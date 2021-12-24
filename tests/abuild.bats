#/usr/bin/env bats

setup() {
	export ABUILD="$PWD/../abuild"
	export ABUILD_SHAREDIR="$PWD/.."
	export ABUILD_CONF=/dev/null
	export REPODEST="$BATS_TEST_TMPDIR"/packages
	export CLEANUP="srcdir bldroot pkgdir deps"
	export WORKDIR="$BATS_TEST_TMPDIR"/work
	export GIT_CONFIG_GLOBAL="$BATS_TEST_TMPDIR"/gitconfig
	export APORTSDIR="$PWD"/testrepo
	export PATH="$PWD/../:$PATH"

	if ! abuild-sign --installed 2>/dev/null; then
		abuild-keygen -ain >/dev/null 2>&1
	fi

	mkdir -p "$WORKDIR"
	printf "[color]\n\tui = always\n" > "$GIT_CONFIG_GLOBAL"
}

@test "abuild: help text" {
	$ABUILD -h
}

@test "abuild: version string" {
	$ABUILD -V
}

@test "abuild: build simple package without deps" {
	cd testrepo/pkg1
	$ABUILD
}

@test "abuild: build failure" {
	cd testrepo/buildfail
	run ERROR_CLEANUP="$CLEANUP" $ABUILD all
	[ $status -ne 0 ]
}

@test "abuild: test check for invalid file names" {
	cd testrepo/invalid-filename
	run ERROR_CLEANUP="$CLEANUP" $ABUILD all
	echo "$output"
	[ $status -ne 0 ]
}

@test "abuild: test check for /usr/lib64" {
	cd testrepo/lib64test
	run $ABUILD all
	[ $status -ne 0 ]
}

@test "abuild: test options=lib64" {
	cd testrepo/lib64test
	options=lib64 $ABUILD
	$ABUILD cleanpkg
}

@test "abuild: test -dbg subpackage" {
	cd testrepo/dbgpkg
	arch=$($ABUILD -A)
	$ABUILD

	mkdir "$BATS_TEST_TMPDIR/dbgpkg-1.0-r0"
	cd "$BATS_TEST_TMPDIR/dbgpkg-1.0-r0"
	tar -xf "$REPODEST"/testrepo/$arch/dbgpkg-1.0-r0.apk
	! [ -e usr/lib/debug ]
	debuginfo=$(readelf -wk usr/bin/hello | grep '^  Separate debug info file: [^/]*\.debug$')
	debuginfo_file=${debuginfo#"  Separate debug info file: "}
	[ "$(nm usr/bin/hello 2>&1)" = "nm: usr/bin/hello: no symbols" ]
	[ usr/bin/hello -ef usr/bin/hello-hard ]

	mkdir "$BATS_TEST_TMPDIR/dbgpkg-dbg-1.0-r0"
	cd "$BATS_TEST_TMPDIR/dbgpkg-dbg-1.0-r0"
	tar -xf "$REPODEST"/testrepo/$arch/dbgpkg-dbg-1.0-r0.apk
	! [ -e usr/bin ]
	[ -n "$(nm usr/lib/debug/usr/bin/$debuginfo_file)" ]
	! [ -e usr/lib/debug/usr/bin/hello-sym.debug ]
	! [ -e usr/lib/debug/usr/bin/hello.debug ] || ! [ -e usr/lib/debug/usr/bin/hello-hard.debug ]
}

@test "abuild: test SETFATTR in -dbg subpackage" {
	cd testrepo/dbgpkg
	ERROR_CLEANUP="$CLEANUP" SETFATTR=true $ABUILD
}

@test "abuild: test SETFATTR failure in -dbg subpackage" {
	cd testrepo/dbgpkg
	run ERROR_CLEANUP="$CLEANUP" SETFATTR=false $ABUILD
	[ $status -ne 0 ]
}

@test "abuild: verify that packages are reproducible built" {
	cd testrepo/pkg1
	arch=$($ABUILD -A)
	pkgs=$($ABUILD listpkg)

	$ABUILD
	checksums=$(cd "$REPODEST"/testrepo/$arch && md5sum $pkgs)
	echo "$checksums"

	$ABUILD cleanpkg all
	checksums2=$(cd "$REPODEST"/testrepo/$arch && md5sum $pkgs)
	echo "$checksums2"

	[ "$checksums" = "$checksums2" ]
}

@test "abuild: test checksum generation" {
	mkdir -p "$BATS_TEST_TMPDIR"/foo
	cat > "$BATS_TEST_TMPDIR"/foo/APKBUILD <<-EOF
		pkgname="foo"
		pkgver="1.0"
		source="test.txt"
	EOF
	echo "foo" > "$BATS_TEST_TMPDIR"/foo/test.txt
	cd "$BATS_TEST_TMPDIR"/foo
	$ABUILD checksum
	. ./APKBUILD && echo "$sha512sums" | sed '/^$/d' > sums
	cat sums
	sha512sum -c sums
}

@test "abuild: test duplicates in checksum generation" {
	mkdir -p "$BATS_TEST_TMPDIR"/foo "$BATS_TEST_TMPDIR"/foo/dir1 "$BATS_TEST_TMPDIR"/foo/dir2
	cat > "$BATS_TEST_TMPDIR"/foo/APKBUILD <<-EOF
		pkgname="foo"
		pkgver="1.0"
		source="dir1/testfile dir2/testfile"
	EOF
	echo "first" > "$BATS_TEST_TMPDIR"/foo/dir1/testfile
	echo "second" > "$BATS_TEST_TMPDIR"/foo/dir2/testfile
	cd "$BATS_TEST_TMPDIR"/foo
	run $ABUILD checksum
	[ $status -ne 0 ]
}

@test "abuild: verify main package does not inherit subpackage dependencies" {
	mkdir -p "$BATS_TEST_TMPDIR"/testrepo/subpkg-dep-leak
	cd "$BATS_TEST_TMPDIR"/testrepo/subpkg-dep-leak
	cat > APKBUILD <<-EOF
		# Maintainer: Natanael Copa <ncopa@alpinelinux.org>
		pkgname="subpkg-dep-leak"
		pkgver=1.0
		pkgrel=0
		pkgdesc="Dummy test package with subpackages and dependencies"
		url="https://gitlab.alpinelinux.org/alpine/aports"
		arch="noarch"
		depends="tar scanelf"
		license="MIT"
		subpackages="\$pkgname-subpkg"
		options="!check"

		package() {
			mkdir -p "\$pkgdir"
		}

		subpkg() {
			depends="sed"
			mkdir -p "\$subpkgdir"
		}
	EOF
	$ABUILD clean unpack prepare build rootpkg

	grep 'depend = tar' pkg/.control.subpkg-dep-leak/.PKGINFO
	grep 'depend = scanelf' pkg/.control.subpkg-dep-leak/.PKGINFO
	! grep 'depend = sed' pkg/.control.subpkg-dep-leak/.PKGINFO

	grep 'depend = sed' pkg/.control.subpkg-dep-leak-subpkg/.PKGINFO
	! grep 'depend = tar' pkg/.control.subpkg-dep-leak-subpkg/.PKGINFO
}

@test "abuild: test py-providers creation" {
	cd testrepo/py3-foo-and-bar
	$ABUILD rootpkg
	run grep -x py3.9:foo=1.0.0-r0 pkg/.control.py3-foo-and-bar/.py-provides
	run grep -x 'provides py3.9:foo=1.0.0-r0' pkg/.control.py3-foo-and-bar/.PKGINFO
	run grep -x py3.9:bar=1.0.0-r0 pkg/.control.py3-foo-and-bar/.py-provides
	run grep -x 'provides py3.9:bar=1.0.0-r0' pkg/.control.py3-foo-and-bar/.PKGINFO
}

@test "abuild: reject initd script with improper shebang" {
	cp -r testrepo/invalid-initd "$BATS_TEST_TMPDIR"
	cd "$BATS_TEST_TMPDIR/invalid-initd"
	sed 's#@source@#test.initd#' APKBUILD.in >APKBUILD

	run $ABUILD unpack

	[[ $output == *"is not an openrc"* ]]
	[[ $status -ne 0 ]]
}

@test "abuild: reject remote initd script with improper shebang" {
	skip 'flaky'
	cp -r testrepo/invalid-initd "$BATS_TEST_TMPDIR"
	cd "$BATS_TEST_TMPDIR/invalid-initd"
	sed 's#@source@#test.initd::https://tpaste.us/ovyL?.initd#' APKBUILD.in >APKBUILD

	$ABUILD fetch
	run $ABUILD unpack

	[[ $output == *"is not an openrc"* ]]
	[[ $status -ne 0 ]]
}

@test "abuild: reject remote initd without initd extension with improper shebang" {
	skip 'Not handled yet'
	cp -r testrepo/invalid-initd "$BATS_TEST_TMPDIR"
	cd "$BATS_TEST_TMPDIR/invalid-initd"
	sed 's#@source@#test.initd::https://tpaste.us/ovyL#' APKBUILD.in >APKBUILD

	run $ABUILD fetch unpack

	[[ $output == *"is not an openrc"* ]]
	[[ $status -ne 0 ]]
}

@test "abuild: valid pkgnames" {
	cd testrepo/test-pkgname
	$ABUILD sanitycheck && TESTNAME="foo" $ABUILD sanitycheck && TESTSUBNAME="foo" $ABUILD sanitycheck
}

@test "abuild: invalid pkgnames" {
	cd testrepo/test-pkgname
	! TESTNAME="" $ABUILD sanitycheck \
		&& ! TESTNAME="-foo" $ABUILD sanitycheck \
		&& ! TESTNAME="name with spaces" $ABUILD sanitycheck
}

@test "abuild: invalid subpkgnames" {
	cd testrepo/test-pkgname
	! TESTSUBNAME="" $ABUILD sanitycheck \
		&& ! TESTSUBNAME="-foo" $ABUILD sanitycheck
}

@test "abuild: invalid subpkg's version" {
	cd testrepo/test-pkgname
	! TESTDEPVER="1.0-0" $ABUILD all
}

