setup() {
	export ABUILD="$PWD/../abuild"
	export ABUMP="$PWD/../abump"
	export ABUILD_KEYGEN="$PWD/../abuild-keygen"
	export ABUILD_SHAREDIR="$PWD/.."
	export ABUILD_CONF=/dev/null
	tmpdir="$BATS_TMPDIR"/abump
	export ABUILD_USERDIR="$tmpdir"/.config
	export PACKAGER="Test User <user@example.com>"
	export REPODEST="$tmpdir"/packages
	mkdir -p $tmpdir
	export CLEANUP="srcdir bldroot pkgdir deps"
	export APORTSDIR="$tmpdir"
	export ABUILD_OPTS=""
	export ABUILD_APK_INDEX_OPTS="--keys-dir=$ABUILD_USERDIR"

	$ABUILD_KEYGEN --append -n

	cd "$tmpdir"
	git init --quiet
	git config user.email "user@example.com"
	git config user.name "Test User"
}

teardown() {
	rm -rf "$tmpdir"
}

@test "abump: help text" {
	$ABUMP -h
}

@test "abump: simple bump" {
	mkdir -p "$tmpdir"/main/foo
	cd "$tmpdir"/main/foo
	echo "first" > foo-1.0.txt
	echo "second" > foo-1.1.txt
	cat > APKBUILD <<-EOF
		# Maintainer: Test user <user@example.com>
		pkgname="foo"
		pkgver=1.0
		pkgrel=0
		pkgdesc="dummy package for test"
		url="https://alpinelinux.org"
		license="MIT"
		arch="noarch"
		source="foo-\$pkgver.txt"
		options="!check"
		package() {
			install -D "\$srcdir"/foo-\$pkgver.txt "\$pkgdir"/foo
		}
	EOF
	$ABUILD checksum
	$ABUILD
	git add APKBUILD foo-1.0.txt
	git commit -m "test commit"

	$ABUMP foo-1.1
}

@test "abump: test bumping same version" {
	mkdir -p "$tmpdir"/main/foo
	cd "$tmpdir"/main/foo
	echo "first" > foo-1.0.txt
	echo "second" > foo-1.1.txt
	cat > APKBUILD <<-EOF
		# Maintainer: Test user <user@example.com>
		pkgname="foo"
		pkgver=1.0
		pkgrel=0
		pkgdesc="dummy package for test"
		url="https://alpinelinux.org"
		license="MIT"
		arch="noarch"
		source="foo-\$pkgver.txt"
		options="!check"
		package() {
			install -D "\$srcdir"/foo-\$pkgver.txt "\$pkgdir"/foo
		}
	EOF
	$ABUILD checksum
	$ABUILD
	git add APKBUILD foo-1.0.txt
	git commit -m "test commit"

	run $ABUMP foo-1.0
	[ $status -ne 0 ]
}

@test "abump: test bumping same version which is not in git" {
	mkdir -p "$tmpdir"/main/foo
	cd "$tmpdir"/main/foo
	echo "first" > foo-1.0.txt
	echo "second" > foo-1.1.txt
	cat > APKBUILD <<-EOF
		# Maintainer: Test user <user@example.com>
		pkgname="foo"
		pkgver=1.0
		pkgrel=0
		pkgdesc="dummy package for test"
		url="https://alpinelinux.org"
		license="MIT"
		arch="noarch"
		source="foo-\$pkgver.txt"
		options="!check"
		package() {
			install -D "\$srcdir"/foo-\$pkgver.txt "\$pkgdir"/foo
		}
	EOF
	$ABUILD checksum
	$ABUILD
	git add APKBUILD foo-1.0.txt
	git commit -m "test commit"

	sed -i -e 's/pkgver=.*/pkgver=1.1/' APKBUILD

	$ABUMP foo-1.1
}
