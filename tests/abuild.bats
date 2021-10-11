#/usr/bin/env bats

setup() {
	export ABUILD="$PWD/../abuild"
	export ABUILD_SHAREDIR="$PWD/.."
	export ABUILD_CONF=/dev/null
	tmpdir="$BATS_TMPDIR"/abuild
	export REPODEST="$tmpdir"/packages
	export CLEANUP="srcdir bldroot pkgdir deps"
	export WORKDIR="$tmpdir"/work
	export GIT_CONFIG_GLOBAL="$tmpdir"/gitconfig
	export APORTSDIR="$PWD"/testrepo
	export PATH="$PWD/../:$PATH"
	export SUDO=doas

	abuild-keygen -ain >/dev/null 2>&1

	mkdir -p "$tmpdir" "$WORKDIR"
	printf "[color]\n\tui = always\n" > "$GIT_CONFIG_GLOBAL"
}

teardown() {
	rm -rf "$tmpdir"
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
	$ABUILD
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
	mkdir -p "$tmpdir"/foo
	cat > "$tmpdir"/foo/APKBUILD <<-EOF
		pkgname="foo"
		pkgver="1.0"
		source="test.txt"
	EOF
	echo "foo" > "$tmpdir"/foo/test.txt
	cd "$tmpdir"/foo
	$ABUILD checksum
	. ./APKBUILD && echo "$sha512sums" | sed '/^$/d' > sums
	cat sums
	sha512sum -c sums
}

@test "abuild: test duplicates in checksum generation" {
	mkdir -p "$tmpdir"/foo "$tmpdir"/foo/dir1 "$tmpdir"/foo/dir2
	cat > "$tmpdir"/foo/APKBUILD <<-EOF
		pkgname="foo"
		pkgver="1.0"
		source="dir1/testfile dir2/testfile"
	EOF
	echo "first" > "$tmpdir"/foo/dir1/testfile
	echo "second" > "$tmpdir"/foo/dir2/testfile
	cd "$tmpdir"/foo
	run $ABUILD checksum
	[ $status -ne 0 ]
}

@test "abuild: test that -dbg should be first" {
	mkdir -p "$tmpdir"/foo
	cat > "$tmpdir"/foo/APKBUILD <<-EOF
		# Maintainer: Test user <user@example.com>
		pkgname="foo"
		pkgver="1.0"
		pkgrel=0
		pkgdesc="dummy package for test"
		url="https://alpinelinux.org"
		license="MIT"
		subpackages="\$pkgname-dev \$pkgname-dbg"
		package() { :; }
	EOF
	cd "$tmpdir"/foo
	run $ABUILD sanitycheck
	[[ $output[1] == *WARNING*dbg* ]]
}

@test "abuild: verify main package does not inherit subpackage dependencies" {
	mkdir -p "$tmpdir"/testrepo/subpkg-dep-leak
	cd "$tmpdir"/testrepo/subpkg-dep-leak
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
	cd testrepo/invalid-initd/
	sed 's#@source@#test.initd#' APKBUILD.in >APKBUILD

	run $ABUILD unpack

	[[ $output == *"is not an openrc"* ]]
	[[ $status -ne 0 ]]
}

@test "abuild: reject remote initd script with improper shebang" {
	cd testrepo/invalid-initd/
	sed 's#@source@#test.initd::https://tpaste.us/ovyL?.initd#' APKBUILD.in >APKBUILD

	$ABUILD fetch
	run $ABUILD unpack

	[[ $output == *"is not an openrc"* ]]
	[[ $status -ne 0 ]]
}

@test "abuild: reject remote initd without initd extension with improper shebang" {
	skip 'Not handled yet'
	cd testrepo/invalid-initd/
	sed 's#@source@#test.initd::https://tpaste.us/ovyL#' APKBUILD.in >APKBUILD

	run $ABUILD fetch unpack

	[[ $output == *"is not an openrc"* ]]
	[[ $status -ne 0 ]]
}
